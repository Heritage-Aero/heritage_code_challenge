const LibraryData = artifacts.require('LibraryData')
const LibraryApp = artifacts.require('LibraryApp')

module.exports = (deployer, network, accounts) => {
  var libraryData
  deployer.deploy(LibraryData)
    .then(instance => {
      libraryData = instance
      return deployer.deploy(LibraryApp, libraryData.address)
    })
}
