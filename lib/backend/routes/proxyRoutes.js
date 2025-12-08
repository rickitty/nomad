const express = require("express");
const axios = require("axios");
const { ensureUserService } = require('../services/authService');

const router = express.Router();

router.post("/sendcode", async (req, res) => {
  try {
    const response = await axios.post(
      "https://smartqyzylorda.curs.kz/api/v1/users/sendcode",
      req.body,
      {
        headers: {
          "Content-Type": "application/json",
        }
      }
    );

    res.json(response.data);
  } catch (error) {
    console.error(error?.response?.data || error);
    res.status(500).json({
      error: "External API error",
      details: error?.response?.data || null
    });
  }
});

router.post("/login", async (req, res) => {
  const { username, code } = req.body;

  try {
    console.log("Login proxy request body:", req.body);
    // 1. Логинимся в API компании
    const response = await axios.post(
      "https://smartqyzylorda.curs.kz/api/v1/users/login",
      { username, code },
      { headers: { "Content-Type": "application/json" } }
    );

    const data = response.data;

    // 2. Обновляем или создаём юзера у тебя в Mongo
    const user = await ensureUserService(username);

    res.json({
      token: data.token,
      refreshToken: data.refreshToken,
      role: user.role,
    });

  } catch (e) {
    console.error("Login error:", e?.response?.data || e);
    res.status(400).json(e?.response?.data || { error: "Login failed" });
  }
});
router.post("/refresh", async (req, res) => {
  const { token, refreshToken } = req.body;

  if (!token || !refreshToken) {
    return res.status(400).json({ error: "Token and refreshToken required" });
  }

  try {
    const response = await axios.post(
      "https://smartqyzylorda.curs.kz/api/v1/users/refresh",
      { token, refreshToken },
      { headers: { "Content-Type": "application/json" } }
    );

    const data = response.data;

    res.json({
      token: data.token,
      refreshToken: data.refreshToken
    });
  } catch (e) {
    console.error("Refresh token error:", e?.response?.data || e);
    res.status(401).json(e?.response?.data || { error: "Refresh failed" });
  }
});

router.get("/profile", async (req, res) => {
  const token = req.headers.authorization?.replace("Bearer ", "");

  if (!token) {
    return res.status(401).json({ error: "Missing token" });
  }

  try {
    const response = await axios.get(
      "https://smartqyzylorda.curs.kz/api/v1/users/profile",
      {
        headers: {
          Authorization: `Bearer ${token}`
        }
      }
    );

    res.json(response.data);
  } catch (error) {
    console.error(error?.response?.data || error);
    res.status(error?.response?.status || 500).json(
      error?.response?.data || { error: "Profile fetch failed" }
    );
  }
});
router.get("/:folder/:id", async (req, res) => {
  const { folder, id } = req.params;
  const token = req.headers.authorization?.replace("Bearer ", "");

  try {
    const response = await axios.get(
      `https://smartqyzylorda.curs.kz/api/v1/files/${folder}/${id}`,
      {
        responseType: "arraybuffer", 
        headers: {
          Authorization: `Bearer ${token}`
        }
      }
    );

    res.set("Content-Type", response.headers["content-type"]);
    res.send(response.data);
  } catch (e) {
    console.log(e.response?.data || e);
    res.status(500).send("File load error");
  }
});
module.exports = router;
