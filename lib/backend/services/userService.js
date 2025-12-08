const User = require('../models/User');

async function makeAdminService(firebaseUser) {
  const user = await User.findOne({ firebaseUid: firebaseUser.uid });

  if (!user) {
    throw new Error("User not found in MongoDB");
  }

  user.role = "admin";
  await user.save();

  return user;
}

async function getWorkersService() {
  return await User.find({ role: 'worker' }).populate('markets');
}

async function assignObjectsToUserService(userId, markets) {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');

  if (!Array.isArray(markets)) {
    throw new Error("Markets must be an array");
  }

  user.markets = markets;
  await user.save();
  
  return user;
}

module.exports = { makeAdminService , getWorkersService, assignObjectsToUserService};
