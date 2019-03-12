const LibraryData = artifacts.require('LibraryData')
const LibraryApp = artifacts.require('LibraryApp')
const truffleAssert = require('truffle-assertions')

contract('Library tests', async (accounts) => {
  let libraryData, libraryApp

  before('setup contract', async () => {
    libraryData = await LibraryData.deployed()
    libraryApp = await LibraryApp.deployed()

    await libraryData.authorizeCaller(libraryApp.address)
  })

  it('Owner addresses correctly set', async () => {
    const ownerLib = await libraryData.libraryOwner()
    const ownerApp = await libraryApp.appOwner()
    assert.equal(accounts[0], ownerLib, 'Wrong library owner address')
    assert.equal(accounts[0], ownerApp, 'Wrong App owner address')
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

  it('Contract owner can change operational status (tested for data contract only)', async function () {
    await libraryData.setOperatingStatus(false)
    assert.equal(await libraryData.operational(), false, 'Failed to change operational status')
  })

  it('Owner can add librarians', async () => {
    // set contract back to operational
    await libraryData.setOperatingStatus(true)
    const tx = await libraryApp.setMembership(accounts[1], true)
    assert(
      await libraryData.librarians.call(accounts[1]),
      'Librarian was not added'
    )
    truffleAssert.eventEmitted(
      tx,
      'Membership',
      ev => {
        return ev.added === true & ev.librarian === accounts[1]
      },
      'Membership event not correctly emitted'
    )
  })

  it('Owner can remove librarians', async () => {
    const tx = await libraryApp.setMembership(accounts[1], false)
    assert.equal(
      await libraryData.librarians.call(accounts[1]),
      false,
      'Librarian was not removed'
    )
    truffleAssert.eventEmitted(
      tx,
      'Membership',
      ev => {
        return ev.added === false & ev.librarian === accounts[1]
      },
      'Membership event not correctly emitted'
    )
  })
/*
  it('Only librarians may check books out to an address', async () => {

  })

  it('A book owner may trade the book to anyone else', async => {

  })

  it('Anyone may check in a book', async () => {

  })

  it('Librarians may add books from the library', async () => {

  })

  it('Librarians may remove books from the library', async () => {

  })

  it("Track the history of a book's ownership", async () => {

  })

  it('Record damage or repair (notes) for a book', async () => {

  })
  */
})
