const express = require("express");
const axios = require("axios");

const router = express.Router();

// Отправка кода
router.post("/sendcode", async (req, res) => {
  try {
    const response = await axios.post(
      "https://smartqyzylorda.curs.kz/api/v1/users/sendcode",
      req.body,
      {
        headers: { "Content-Type": "application/json" }
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

// Логин
router.post("/login", async (req, res) => {
  const { username, code } = req.body;

  try {
    const response = await axios.post(
      "https://smartqyzylorda.curs.kz/api/v1/users/login",
      { username, code },
      { headers: { "Content-Type": "application/json" } }
    );

    res.json(response.data); // Возвращаем напрямую токены от сервиса
  } catch (e) {
    console.error("Login error:", e?.response?.data || e);
    res.status(400).json(e?.response?.data || { error: "Login failed" });
  }
});

// Обновление токена
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

    res.json(response.data); // Возвращаем напрямую новые токены
  } catch (e) {
    console.error("Refresh token error:", e?.response?.data || e);
    res.status(401).json(e?.response?.data || { error: "Refresh failed" });
  }
});

// Профиль
router.get("/profile", async (req, res) => {
  const token = req.headers.authorization?.replace("Bearer ", "");

  if (!token) {
    return res.status(401).json({ error: "Missing token" });
  }

  try {
    const response = await axios.get(
      "https://smartqyzylorda.curs.kz/api/v1/users/profile",
      { headers: { Authorization: `Bearer ${token}` } }
    );

    res.json(response.data);
  } catch (error) {
    console.error(error?.response?.data || error);
    res.status(error?.response?.status || 500).json(
      error?.response?.data || { error: "Profile fetch failed" }
    );
  }
});

// Загрузка файлов
router.get("/:folder/:id", async (req, res) => {
  const { folder, id } = req.params;
  const token = req.headers.authorization?.replace("Bearer ", "");

  try {
    const response = await axios.get(
      `https://smartqyzylorda.curs.kz/api/v1/files/${folder}/${id}`,
      {
        responseType: "arraybuffer",
        headers: { Authorization: `Bearer ${token}` }
      }
    );

    res.set("Content-Type", response.headers["content-type"]);
    res.send(response.data);
  } catch (e) {
    console.error(e.response?.data || e);
    res.status(500).send("File load error");
  }
});

module.exports = router;
