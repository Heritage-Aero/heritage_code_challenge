pragma solidity ^0.5.0;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract LibraryData {
    using SafeMath for uint;

    // ----------------- VARIABLES
    address public libraryOwner;

    // To track registered librarians
    mapping(address => bool) public librarians;

    // struct to check the history of the check In
    struct Transfer {
        /* who is transfering the book
        library in case of check out
        borrower in case of check in
        */
        address from;
        // Describe the changed made to book e.g repair or damages
        string notes;
    }



    struct Book {
        string title;
        string author;
        uint publishedDate;
        address originLibrarian;
        address currentOwner;
        bool checkedOut;
        uint index; // var used for CRUD pattern
        Transfer[] transfers;
        uint transfersCount;
        // price?
        // uint price;
    }

    /* Track all books in library
    key = hash(title, author, publishedDate) with a CRUD pattern
    https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a
    */
    mapping(bytes32 => Book) public books;
    bytes32[] bookKeys;

    // Contract operational status control
    bool public operational = false;

    // Track authorized app contracts (upgradability requirement)
    mapping(address => bool) public authorizedCallers;
    // ----------------- EVENTS

    // ---------------- CONSTRUCTOR
    constructor () public {
        // Contract is active
        operational = true;
        libraryOwner = msg.sender;
        // owner is registered librarian
        librarians[msg.sender] = true;
    }

    // ----------------- MODIFIERS
    modifier isOwner() {
        require(
            msg.sender == libraryOwner,
            "Only library owner can perform this action"
        );
        _;
    }

    modifier isOperational() {
        require(operational, "Contract is currently not operational");
        _;
    }

    // restrict function calls to previously authorized addresses
    modifier callerAuthorized() {
        require(authorizedCallers[msg.sender] == true, "Address not authorized to call this function");
        _;
    }

    modifier differentModeRequest(bool status) {
        require(status != operational, "Contract already in the state requested");
        _;
    }

    // ----------------- UTILITY FUNCTIONS
    function setOperatingStatus(bool mode)
    external
    isOwner
    differentModeRequest(mode)
    {
        operational = mode;
    }

    function authorizeCaller(address callerAddress)
    external
    isOperational
    {
        authorizedCallers[callerAddress] = true;
    }

    function isRegistered(address librarian)
    external
    callerAuthorized
    view
    returns (bool registered)
    {
        registered = librarians[librarian];
    }

    function getBookKey
    (
        string memory title,
        string memory author,
        uint publishedDate
    )
    public
    pure
    returns(bytes32 bookKey)
    {
        bookKey = keccak256(abi.encodePacked(title, author, publishedDate));
    }

    function isBook(bytes32 bookKey)
    public
    view
    returns(bool isIndeed)
    {
        if (bookKeys.length == 0) return false;
        return (bookKeys[books[bookKey].index] == bookKey);
    }

    function getBookOwner(bytes32 bookKey)
    public
    view
    returns (address bookOwner)
    {
        bookOwner = books[bookKey].currentOwner;
    }

    function getBookOriginLibrarian(bytes32 bookKey)
    public
    view
    returns (address librarian)
    {
        librarian = books[bookKey].originLibrarian;
    }

    function isCheckedOut(bytes32 bookKey)
    external
    view
    returns (bool out)
    {
        out = books[bookKey].checkedOut;
    }

    function recordTransfer
    (
        bytes32 bookKey,
        address from,
        string memory notes
    )
    internal
    {
        Transfer memory transfer = Transfer(from, notes);
        books[bookKey].transfersCount = books[bookKey].transfers.push(transfer);
    }

    function getTransfer
    (
        bytes32 bookKey,
        uint index
    )
    external
    view
    returns (address fromAddress, string memory notesTransfer)
    {
        require(isBook(bookKey), "This book does not exist");
        require(
            index <= books[bookKey].transfersCount,
            "Index out of range"
        );
        fromAddress = books[bookKey].transfers[index].from;
        notesTransfer = books[bookKey].transfers[index].notes;
    }

    function getTransfersCount(bytes32 bookKey)
    external
    view
    returns (uint num)
    {
        num = books[bookKey].transfersCount;
    }

    // ----------------- SMART CONTRACT CORE FUNCTIONS
    // Add or remove (depending on add arg)
    function setMembership(address librarian, bool add)
    external
    callerAuthorized
    isOperational
    {
        librarians[librarian] = add;
    }

    function insertBook
    (
        string calldata author,
        string calldata title,
        uint publishedDate,
        address _originLibrarian
    )
    external
    callerAuthorized
    isOperational
    returns (uint index)
    {
        // Generate book key
        bytes32 bookKey = getBookKey(author, title, publishedDate);

        // Insert book in collection
        books[bookKey].author = author;
        books[bookKey].title = title;
        books[bookKey].publishedDate = publishedDate;
        books[bookKey].originLibrarian = _originLibrarian;
        books[bookKey].currentOwner = _originLibrarian;
        books[bookKey].index = bookKeys.push(bookKey).sub(1);
        index = bookKeys.length.sub(1);
    }

    // Very smart delete pattern from:
    // https://medium.com/@robhitchens/solidity-crud-part-2-ed8d8b4f74ec
    function deleteBook(bytes32 bookKey)
    external
    callerAuthorized
    isOperational
    returns (uint index)
    {
        // get key of book to delete
        uint indexBookToDelete = books[bookKey].index;
        /* move book in last position of the index into the position
        of the book to be deleted
        */
        bytes32 fillBookKey =  bookKeys[bookKeys.length.sub(1)];
        bookKeys[indexBookToDelete] = fillBookKey;
        // Update replacement book index
        books[fillBookKey].index = indexBookToDelete;
        // delete last book of the index
        index = bookKeys.length--;

    }

    function checkOutBook
    (
        address borrower,
        bytes32 bookKey,
        string calldata notes
    )
    external
    callerAuthorized
    isOperational
    {
        books[bookKey].checkedOut = true;
        recordTransfer(bookKey, books[bookKey].currentOwner, notes);
        books[bookKey].currentOwner = borrower;
    }

    function checkInBook
    (
        bytes32 bookKey,
        string calldata notes,
        address from
    )
    external
    callerAuthorized
    isOperational
    {
        books[bookKey].checkedOut = false;
        recordTransfer(bookKey, from, notes);
        books[bookKey].currentOwner = books[bookKey].originLibrarian;
    }

}
