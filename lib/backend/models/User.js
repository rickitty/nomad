const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true }, 
  role: { type: String, enum: ['worker', 'admin'], default: 'worker' },
  markets: [
    {
      name: { type: String },
      address: { type: String },
      location: {
        lat: { type: Number },
        lng: { type: Number }
      },
      geoAccuracy: { type: Number },
      type: { type: String },
      workHours: { type: String }
    }
  ],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
