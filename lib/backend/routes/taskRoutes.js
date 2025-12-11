const express = require('express');
const router = express.Router();

const axios = require('axios');
const FormData = require('form-data');
const { getBearerToken } = require('../auth');
const upload = require('../middleware/upload');

const QYZ_API_BASE = 'https://qyzylorda-idm-test.curs.kz/api/v1/monitoring';

const TASK_STATUS = {
  ASSIGNED: 1,
  IN_PROGRESS: 2,
  AWAITING_REVIEW: 3,
  COMPLETED: 4,
  CANCELED: 5,
};

router.post('/create-task', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }

    const { token: _ignore, ...taskData } = req.body;

    const response = await axios.post(
      `${QYZ_API_BASE}/task/create`,
      taskData,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      }
    );

    res.status(201).json(response.data);

  } catch (e) {
    console.error("Task create error:", e.response?.data || e.message);
    res.status(500).json({ error: e.response?.data || e.message });
  }
});


router.get('/all', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }

    const response = await axios.get(
      `${QYZ_API_BASE}/task`,
      {
        headers: { Authorization: `Bearer ${token}` },
      },
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);
    res.status(500).json({ error: e.response?.data || e.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }

    const { id } = req.params;

    const response = await axios.get(
      `${QYZ_API_BASE}/task/${id}`,
      {
        headers: { Authorization: `Bearer ${token}` },
      },
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);
    res.status(500).json({ error: e.response?.data || e.message });
  }
});

router.put("/:id/status", async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: "Bearer token is required" });
    }

    const { id } = req.params;
    const body = req.body;

    const response = await axios.put(
      `${QYZ_API_BASE}/task/${id}`,
      body,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);

    const status = e.response?.status || 500;

    res.status(status).json({
      error: e.response?.data || e.message,
    });
  }
});

router.put("/detail/:id", async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: "Bearer token is required" });
    }

    const { id } = req.params;
    const body = req.body; 

    const response = await axios.put(
      `${QYZ_API_BASE}/task/detail/${id}`, 
      body,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      }
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);

    res.status(e.response?.status || 500).json({
      error: e.response?.data || e.message,
    });
  }
});


router.put(
  '/detail/update',
  upload.fields([
    { name: 'PhotoProduct', maxCount: 1 },
    { name: 'PhotoPrice',  maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const token = getBearerToken(req);
      if (!token) {
        return res.status(400).json({ error: 'Bearer token is required' });
      }

      const formData = new FormData();

      // Поля
      ['TaskDetailId', 'GoodId', 'PriceUnit', 'Lat', 'Lng'].forEach((key) => {
        if (req.body[key] !== undefined) {
          formData.append(key, req.body[key]);
        }
      });

      // Файлы
      if (req.files?.PhotoProduct?.[0]) {
        const file = req.files.PhotoProduct[0];
        formData.append('PhotoProduct', file.buffer, {
          filename: file.originalname,
          contentType: file.mimetype,
        });
      }

      if (req.files?.PhotoPrice?.[0]) {
        const file = req.files.PhotoPrice[0];
        formData.append('PhotoPrice', file.buffer, {
          filename: file.originalname,
          contentType: file.mimetype,
        });
      }

      const response = await axios.put(
        `${QYZ_API_BASE}/taskDetail/update`,
        formData,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            ...formData.getHeaders(),
          },
        }
      );

      res.json(response.data);
    } catch (e) {
      console.error(e.response?.data || e.message);
      res.status(500).json({ error: e.response?.data || e.message });
    }
  }
);



module.exports = router;