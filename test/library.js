const LibraryData = artifacts.require('LibraryData')
const LibraryApp = artifacts.require('LibraryApp')

contract('Library tests', async (accounts) => {
  let libraryData, libraryApp
  const libraryOwner = accounts[0]
  const appOwner = accounts[0]

  before('setup contract', async () => {
    libraryData = await LibraryData.deployed()
    libraryApp = await LibraryApp.deployed()

    await libraryData.authorizeCaller(libraryApp.address)
  })

  it('Has correct initial operational values', async function () {
    // Get operating status
    const statusData = await libraryData.operational()
    const statusApp = await libraryApp.operational()
    assert(statusData, 'Data contract has an incorrect initial operating status value')
    assert(statusApp, 'Data contract has an incorrect initial operating status value')
  })

  it('(Data contract) Blocks access to setOperatingStatus() for non-Contract Owner account (tested only for data contract)', async function () {
    // Ensure that access is denied for non-Contract Owner account
    let rejected = false
    try {
      await libraryData.setOperatingStatus(false, { from: accounts[1] })
    } catch (error) {
      rejected = true
    }
    assert(rejected, 'Access to operational control function was not blocked')
  })

  it('(Data contract) Contract owner can change operational status', async function () {
    await libraryData.setOperatingStatus(false)
    assert.equal(await libraryData.operational(), false, 'Failed to change operational status')
  })
})
