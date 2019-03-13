# A<sup>3</sup> by Airbus Group - Solidity Engineer - Solidity Challenge

Solidity Smart Contracts to manage the inventory of a book library.

## [Initial Requirements](https://github.com/Heritage-Aero/heritage_code_challenge/blob/master/README.md)
1. The library has an owner and librarians.:heavy_check_mark:
2. The owner may add or remove librarians.:heavy_check_mark:
3. Only librarians may check books out to an address.:heavy_check_mark:
4. A book owner may trade the book to anyone else. :heavy_check_mark:
  - Only the owner of a book can put it on sale
  - Anyone can buy a book which is on sale
5. Anyone may check in a book.:white_check_mark:  
I changed this requirement into *anyone except librarians...* because I found
weird to let librarians check back in books to themselves.
6. Librarians may add/remove books to the library. :heavy_check_mark:
7. Track the history of the book's ownership. :heavy_check_mark:  
To fulfill this requirement I am using an array of `Transfer` structs within the Book struct.
8. Record damage & repair for a book.:heavy_check_mark:  
This is also covered by a book's `Transfer` struct.
9. View book status/history. :white_check_mark:  
For a given book, the view/get function returns all Book's parameters but only the last recorded transfer.
10. Log relevant events. :heavy_check_mark:
11. Use of the following tools/resource: :heavy_check_mark:
  - Truffle Framework
  * GitHub
  * Mocha/Chai
  * OpenZeppelin
  * npm
12. Perform unit tests :heavy_check_mark:

### Additional requirements
On top of the requirements which were already specified, I also fulfilled the following:  
13. Separate contract data from app logic (`libraryData.sol` and `libraryApp.sol`) to ensure upgradability. In the case where business rules were to change, a new app contract would be deployed without modifying the data contract.  
14. Control which app contracts can call the data contract (`callerAuthorized` modifier and proper migration set up).
15. Operational control: set a boolean flag (`operational`)to stop the contracts in case something goes wrong (`setOperationalStatus()`).  
16. Follow a CRUD pattern to manage books. [Credit Rob Hitchens](https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a)  
17. Follow security [best practice for payments/transfer](https://solidity.readthedocs.io/en/v0.4.24/common-patterns.html#withdrawal-from-contracts): don't push the transfers but let users pull/withdraw their credited amount.

## Data structures
- Tracks registered librarians: `librarians` mapping
- Track books
  - `Book` struct
    - Track check out/in: `checkedOut` boolean
    - Track history of ownership and e.g damages: `Transfer` struct and `Transfers[]` array
  - `books` mapping
  - `bookKeys` hash keys array
- Trade books
  - `price` property in Book struct
  - pattern: put book on sale, buy book, withdrawal
## Getting Started
1. Clone repository
2. Install dependencies: `npm install`
3. Run tests: `npm run test`

## Further developments
- Build front end (e.g with drizzle)
- Make contract ready for prod: some variables (e.g `withdrawals` mapping) were deliberately left with a public visibility to ease unit testing. This should be changed.
