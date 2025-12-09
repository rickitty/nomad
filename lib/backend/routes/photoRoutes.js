const express = require('express');
const axios = require('axios');
const upload = require('../middleware/upload');
const router = express.Router();

// например, URL сервиса, который принимает картинку
const MONITORING_BASE = process.env.MONITORING_BASE_URL || 'http://localhost:5000';

router.put(
  '/api/v1/monitoring/taskDetail/update',
  upload.fields([
    { name: 'PhotoProduct', maxCount: 1 },
    { name: 'PhotoPrice', maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const {
        TaskDetailId,
        GoodId,
        PriceUnit,
        Lat,
        Lng,
      } = req.body;

      const files = req.files || {};

      let photoProductName = null;
      let photoPriceName = null;

      // если пришла фотка товара – отправляем в /picture/{FileName}
      if (files.PhotoProduct && files.PhotoProduct[0]) {
        const file = files.PhotoProduct[0];
        const fileName = Date.now() + '-' + file.originalname;

        await axios.post(
          `${MONITORING_BASE}/api/v1/monitoring/picture/${encodeURIComponent(fileName)}`,
          file.buffer,
          {
            headers: {
              'Content-Type': 'application/octet-stream',
            },
          },
        );

        photoProductName = fileName;
      }

      // если пришла фотка ценника – аналогично
      if (files.PhotoPrice && files.PhotoPrice[0]) {
        const file = files.PhotoPrice[0];
        const fileName = Date.now() + '-' + file.originalname;

        await axios.post(
          `${MONITORING_BASE}/api/v1/monitoring/picture/${encodeURIComponent(fileName)}`,
          file.buffer,
          {
            headers: {
              'Content-Type': 'application/octet-stream',
            },
          },
        );

        photoPriceName = fileName;
      }

      // дальше сохраняешь в БД:
      // TaskDetailId, GoodId, PriceUnit, Lat, Lng, photoProductName, photoPriceName
      // ...

      return res.json({ ok: true });
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: 'Ошибка сохранения товара' });
    }
  },
);

module.exports = router;
