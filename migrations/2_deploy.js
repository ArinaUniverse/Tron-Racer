const horse = artifacts.require("newHorse");
const race = artifacts.require("race");

module.exports = function(deployer) {
  deployer.deploy(horse)
  deployer.deploy(race)
};