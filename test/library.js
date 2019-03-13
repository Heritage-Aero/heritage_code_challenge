const LibraryData = artifacts.require('LibraryData')
const LibraryApp = artifacts.require('LibraryApp')
const truffleAssert = require('truffle-assertions')

contract('Library tests', async (accounts) => {
  let libraryData, libraryApp
  const book = {
    title: 'Test',
    author: 'Gry0u',
    publishedDate: Math.floor(Date.now() / 1000),
    originLibrarian: 'Library'
  }

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

  it('Librarians may add books to the library', async () => {
    // add back librarian
    await libraryApp.setMembership(accounts[1], true)
    const tx = await libraryApp.insertBook(
      book.title,
      book.author,
      book.publishedDate,
      { from: accounts[1] }
    )
    const bookKey = await libraryData.getBookKey(book.title, book.author, book.publishedDate)
    assert(await libraryData.isBook(bookKey), 'Book was not added correctly')
    truffleAssert.eventEmitted(
      tx,
      'BookAdded',
      ev => {
        return ev.title == book.title &
        ev.author == book.author &
        ev.publishedDate == book.publishedDate &
        ev.originLibrarian == accounts[1]
      },
      'BookAdded event not emitted correctly'
    )
  })

  it('Librarians may remove books from the library', async () => {
    const tx = await libraryApp.deleteBook(
      book.title,
      book.author,
      book.publishedDate,
      { from: accounts[1] }
    )
    const bookKey = await libraryData.getBookKey(book.title, book.author, book.publishedDate)
    assert.equal(
      await libraryData.isBook(bookKey),
      false,
      'Book was not deleted correctly'
    )
    truffleAssert.eventEmitted(
      tx,
      'BookDeleted',
      ev => {
        return ev.title == book.title &
        ev.author == book.author &
        ev.publishedDate == book.publishedDate
      },
      'BookDeleted event not emitted correctly'
    )
  })

  it('Only librarians may check books out to an address. The transfer is recorded on the book. Note may be added', async () => {
    // re add book to library
    await libraryApp.insertBook(
      book.title,
      book.author,
      book.publishedDate,
      { from: accounts[1] }
    )
    // address not regsitered as librarian fails to check out book
    let fail = false
    try {
      await libraryApp.checkOutBook(
        accounts[3],
        book.title,
        book.author,
        book.publishedDate,
        "Scratch on cover",
        { from: accounts[2] }
      )
    } catch (error) {
      fail = true
    }
    assert(fail, 'Book check out should have failed')

    // check out book from a librarian address
    const tx = await libraryApp.checkOutBook(
      accounts[3],
      book.title,
      book.author,
      book.publishedDate,
      "Scratch on cover",
      { from: accounts[1] }
    )

    // Assertions
    const bookKey = await libraryData.getBookKey(book.title, book.author, book.publishedDate)
    const _book = await libraryData.books.call(bookKey)
    assert(_book.checkedOut, 'Book should be checked out')
    assert.equal(_book.currentOwner, accounts[3], 'Wrong book owner')

    const transfer = await libraryData.getTransfer(bookKey, 0)
    assert.equal(transfer[0], accounts[1], "Wrong from property in book's transfer record")
    assert.equal(transfer[1], 'Scratch on cover', "Wrong notes in book's transfer record")

    truffleAssert.eventEmitted(
      tx,
      'BookCheckedOut',
      ev => {
        return ev.borrower == accounts[3]
      },
      'Event not emitted correctly'
    )
  })

  it('Anyone may check in a book', async () => {
    const tx = await libraryApp.checkInBook(
      book.title,
      book.author,
      book.publishedDate,
      'Stains on back cover',
      // test if other person than owner can check in
      { from: accounts[4] }
    )

    const bookKey = await libraryData.getBookKey(book.title, book.author, book.publishedDate)
    const _book = await libraryData.books.call(bookKey)
    assert.equal(_book.checkedOut, false, 'Book should be checked in')
    assert.equal(_book.currentOwner, _book.originLibrarian, 'Wrong book owner')

    const transfer = await libraryData.getTransfer(bookKey, 1)
    assert.equal(transfer[0], accounts[4], "Wrong from property in book's transfer record")
    assert.equal(transfer[1], 'Stains on back cover', "Wrong notes in book's transfer record")

    truffleAssert.eventEmitted(
      tx,
      'BookCheckedIn',
      ev => {
        return ev.originLibrarian == accounts[1]
      },
      'Event not emitted correctly'
    )

  })

  it('Can get/view a book', async () => {
    const {
      originLibrarian,
      currentOwner,
      checkedOut,
      transfersCount,
      lastTransferFrom,
      lastTransferNotes
    } = await libraryApp.getBook(
      book.title,
      book.author,
      book.publishedDate
    )
    assert.equal(originLibrarian, accounts[1], 'Wrong originLibrarian')
    assert.equal(currentOwner, accounts[1], 'Wrong currentOwner')
    assert(!checkedOut, 'Wrong checkedOut status')
    assert.equal(transfersCount, 2, 'Wrong transfers count')
    assert.equal(lastTransferFrom, accounts[4], 'Wrong from last transfer')
    assert.equal(lastTransferNotes, 'Stains on back cover', 'Wrong last notes')

  })

  it('(trade) A book owner can put his book on sale', async () => {
    // owner (here the librarian account[1]) puts book for sale
    const _price = web3.utils.toWei('1', 'ether')
    const tx = await libraryApp.sellBook(
      book.title,
      book.author,
      book.publishedDate,
      web3.utils.toWei('1', 'ether'),
      'Stains removed before sale',
      { from: accounts[1] }
    )

    // assertions
    const {
      price,
      lastTransferFrom,
      lastTransferNotes
    } = await libraryApp.getBook(
      book.title,
      book.author,
      book.publishedDate
    )

    assert.equal(lastTransferNotes, 'Stains removed before sale', 'Wrong notes attribute')
    assert.equal(lastTransferFrom, accounts[1], 'From from attribute in last transfer record')
    assert.equal(_price, +price, 'Wrong sale price')

    truffleAssert.eventEmitted(tx, 'BookPutOnSale', ev => {
      return ev.title == book.title & +ev.price == _price
    }, 'Event not emitted correctly')
  })

  it('(trade) Anyone can buy a book put on sale', async () => {
    // account 3 buys book
    const _price = web3.utils.toWei('1', 'ether')
    const balanceBefore = await web3.eth.getBalance(accounts[3])
    const tx = await libraryApp.buyBook(
      book.title,
      book.author,
      book.publishedDate,
      { from: accounts[3], value: _price, gasPrice: 0 }
    )
    const balanceAfter = await web3.eth.getBalance(accounts[3])
    const {
      price,
      currentOwner
    } = await libraryApp.getBook(
      book.title,
      book.author,
      book.publishedDate
    )
    const withdrawal = await libraryData.withdrawals.call(accounts[1])

    assert.equal(+balanceBefore - _price, +balanceAfter, "Buyer's balance didn't decrease")
    assert.equal(withdrawal, web3.utils.toWei('1', 'ether'), 'Wrong credited amount')
    assert.equal(+price, 0, 'Wrong sale price (should be back to 0)')
    assert.equal(currentOwner, accounts[3], 'Wrong current owner')
    assert

    truffleAssert.eventEmitted(tx, 'BookSold', ev => {
      return ev.title == book.title & +ev.price == _price
    }, 'Wrong event emitted')
  })

  it('(trade) After a sale, a seller can withdraw his/her credited amount', async () => {
    const balanceBefore = await web3.eth.getBalance(accounts[1])
    const tx = await libraryApp.withdraw({
      from: accounts[1],
      gasPrice: 0
    })
    const balanceAfter = await web3.eth.getBalance(accounts[1])

    assert.equal(
      +balanceBefore + +web3.utils.toWei('1', 'ether'), +balanceAfter,
      'Withdrawal unsecessful'
    )
    truffleAssert.eventEmitted(tx, 'Paid', ev => {
      return ev.recipient == accounts[1]
    }, 'Wrong event emitted')
  })
})
