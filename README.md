# A<sup>3</sup> by Airbus Group - Solidity Engineer - Solidity Challenge

Solidity Smart Contracts to manage the inventory of a book library.
* List all assumptions.
* Code without a corresponding unit test will not be considered.

## Initial Requirements
1. The library has an owner and librarians.:heavy_check_mark:  
2. The owner may add or remove librarians.:heavy_check_mark:
3. Only librarians may check books out to an address.:heavy_check_mark:
4. A book owner may trade the book to anyone else.
5. Anyone may check in a book.:white_check_mark:  
I changed this requirement into *anyone except librarians..* because I found
weird to let librarians check back in book to themselves.
6. Librarians may add/remove books to the library. :heavy_check_mark:
7. Track the history of the book's ownership. :heavy_check_mark:  
To fulfill this requirement I am using an array of `Transfer` structs within the Book struct.
8. Record damage & repair for a book.:heavy_check_mark:  
This is also covered by the `Transfer` structs.
9. View book status/history. :white_check_mark:  
For a given book, the view/get function returns all Book parameters but only the last recorded transfer.
10. Log relevant events. :heavy_check_mark:
11. Use of the following tools/resource: :heavy_check_mark:
  - Truffle Framework
  * GitHub
  * Mocha/Chai
  * OpenZeppelin
  * npm
12. Perform unit tests :heavy_check_mark:

On top of these already specified requirements, I also fulfilled the following:  
13. Separate contract data from app logic (`libraryData.sol` and `libraryApp.sol`) to ensure upgradability. In the case where business rules were to change, a new app contract would be deployed without modifying the data contract.  
14. Operational control: set a boolean flag to stop the contracts in case something goes wrong.  
15. Follow a CRUD pattern to manage books. [Credit Rob Hitchens](https://medium.com/@robhitchens/solidity-crud-part-2-ed8d8b4f74ec)

## Getting Started
1. Clone repository
2. Install dependencies: `npm install`
3. Run tests: `npm run test`
