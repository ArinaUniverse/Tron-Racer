const horse = artifacts.require("horseContract");
const race = artifacts.require("race");

module.exports = function(deployer) {
  deployer.deploy(horse)
  deployer.deploy(race)
};