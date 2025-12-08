const express = require('express');
const router = express.Router();
const axios = require('axios');
const { getBearerToken } = require('../auth');

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

router.put('/detail/update', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }

    const detailData = req.body;  

    const response = await axios.put(
      `${QYZ_API_BASE}/taskDetail/update`,
      detailData,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      },
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);
    res.status(500).json({ error: e.response?.data || e.message });
  }
});



router.post('/:taskId/start', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }

    const { taskId } = req.params;
    const { lat, lng } = req.body || {}; 

    const body = {
      status: TASK_STATUS.IN_PROGRESS, 
      lat,
      lng,
    };

    const response = await axios.put(
      `${QYZ_API_BASE}/task/${taskId}`,
      body,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      },
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);
    res.status(500).json({ error: e.response?.data || e.message });
  }
});

router.post('/:taskId/complete', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }

    const { taskId } = req.params;

    const response = await axios.put(
      `${QYZ_API_BASE}/task/${taskId}`,
      {
        status: TASK_STATUS.COMPLETED, 
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      },
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);
    res.status(500).json({ error: e.response?.data || e.message });
  }
});
module.exports = router;