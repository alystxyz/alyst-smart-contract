const CreateCampaign = artifacts.require("CreateCampaign");

module.exports = function (deployer) {
  deployer.deploy(CreateCampaign);
};
