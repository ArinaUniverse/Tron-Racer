const horse = artifacts.require("newHorse");
const race = artifacts.require("race");

module.exports = async function(deployer) {
  let h = await horse.deployed();
  let r = await race.deployed();
  await r.setHorse(h.address);
  await h.setRace(r.address);
  console.log(`horse合約: ${h.address}`)
  console.log(`race合約: ${r.address}`)
};