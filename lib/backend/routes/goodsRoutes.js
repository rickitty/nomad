const express = require('express');
const router = express.Router();
const axios = require('axios');
const { getBearerToken } = require('../auth');

const QYZ_API_BASE = 'https://qyzylorda-idm-test.curs.kz/api/v1/monitoring';

router.get('/', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(400).json({ error: 'Bearer token is required' });
    }

    const response = await axios.get(
      `${QYZ_API_BASE}/goods`,
      {
        headers: { Authorization: `Bearer ${token}` },
        params: req.query,
      },
    );

    res.json(response.data);
  } catch (e) {
    console.error(e.response?.data || e.message);
    res.status(500).json({ error: e.response?.data || e.message });
  }
});

module.exports = router;
