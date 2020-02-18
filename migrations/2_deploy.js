const horse = artifacts.require("HorseContract");
const race = artifacts.require("race");

module.exports = function(deployer) {
  deployer.deploy(horse)
  deployer.deploy(race)
};