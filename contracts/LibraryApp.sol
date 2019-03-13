pragma solidity ^0.5.0;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


// Interface contract
interface LibraryData {
    function setMembership(address librarian, bool add) external;

    function insertBook(
        string calldata author,
        string calldata title,
        uint publishedDate,
        address originLibrarian
    )
    external returns(uint);

    function deleteBook(bytes32 bookKey) external returns (uint);

    function checkOutBook(address borrower, bytes32 bookKey, string calldata notes) external;

    function checkInBook
    (
        bytes32 bookKey,
        string calldata notes,
        address from
    )
    external;

    function sellBook
    (
        bytes32 bookKey,
        uint price,
        address seller,
        string calldata notes
    )
    external;

    function buyBook(bytes32 bookKey, address buyer) external payable;
    function withdraw(address recipient) external;

    function libraryOwner() external view returns(address);
    function isRegistered(address librarian) external view returns(bool);

    function getBookOwner(bytes32 bookKey)
    external
    view
    returns (address);

    function getBookOriginLibrarian(bytes32 bookKey)
    external
    view
    returns (address);

    function isBook(bytes32 bookKey) external view returns(bool);
    function isCheckedOut(bytes32 bookKey) external view returns (bool);
    function getTransfer(bytes32 bookKey, uint index) external view returns (address from, string memory notes);
    function getTransfersCount(bytes32 bookKey) external view returns (uint);
    function getBookPrice(bytes32 bookKey) external view returns (uint);
}


contract LibraryApp {
    using SafeMath for uint;

    // ----------------- VARIABLES
    LibraryData libraryData;
    address public appOwner;
    bool public operational = false;
    // ----------------- EVENTS
    event Membership(address librarian, bool added);
    event BookAdded(string title, string author, uint publishedDate, address originLibrarian);
    event BookDeleted(string title, string author, uint publishedDate);

    event BookCheckedOut(
        address borrower,
        string author,
        string title,
        uint publishedDate);
    event BookCheckedIn(
        string title,
        string author,
        uint publishedDate,
        address originLibrarian);
    event BookPutOnSale(
        string title,
        string author,
        uint publishedDate,
        uint price
    );
    event BookSold(
        string title,
        string author,
        uint publishedDate,
        uint price
    );
    event Paid(address recipient);

    // ---------------- CONSTRUCTOR
    constructor (address libraryDataAddress) public {
        operational = true;
        appOwner = msg.sender;
        libraryData = LibraryData(libraryDataAddress);
    }

    // ----------------- MODIFIERS
    modifier isAppOwner() {
        require(msg.sender == appOwner, "Caller is not App owner");
        _;
    }

    modifier isLibraryOwner() {
        require(
            msg.sender == libraryData.libraryOwner(),
            "Only the library owner can perform this action"
        );
        _;
    }

    modifier isOperational() {
        require(operational, "Contract is currently not operational");
        _;
    }

    // To avoid spending gas trying to put the contract in a state it already is in
    modifier differentModeRequest(bool status) {
        require(status != operational, "Contract already in the state requested");
        _;
    }

    /* Similarly we don't want to spend gas trying to add already regsitered librarians
    or to remove non registered librarians
    */
    modifier differentMembershipRequest(address librarian, bool add) {
        bool registered = libraryData.isRegistered(librarian);
        require(
            add != registered,
            "This librarian is already registered (if trying to add) or is not registered yet (if trying to remove)"
        );
        _;
    }

    // Check is a librarian is registered
    modifier isLibrarian() {
        require(
            libraryData.isRegistered(msg.sender),
            "Must be registered as librarian to perform this action"
        );
        _;
    }

    modifier bookExists(
        string memory title,
        string memory author,
        uint publishedDate
    ) {
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        require(libraryData.isBook(bookKey), "This book is not part of the library");
        _;
    }

    // ----------------- HELPERS FUNCTIONS
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

    // ----------------- SMART CONTRACT FUNCTIONS
    function setMembership(address librarian, bool add)
    external
    isLibraryOwner
    isOperational
    differentMembershipRequest(librarian, add)
    {
        libraryData.setMembership(librarian, add);
        emit Membership(librarian, add);
    }

    function insertBook
    (
        string calldata title,
        string calldata author,
        uint publishedDate
    )
    external
    isOperational
    isLibrarian
    {
        libraryData.insertBook(title, author, publishedDate, msg.sender);
        emit BookAdded(title, author, publishedDate, msg.sender);
    }

    function deleteBook
    (
        string calldata title,
        string calldata author,
        uint publishedDate
    )
    external
    isOperational
    isLibrarian
    bookExists(title, author, publishedDate)
    {
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        libraryData.deleteBook(bookKey);
        emit BookDeleted(title, author, publishedDate);
    }

    function checkOutBook
    (
        address borrower,
        string calldata title,
        string calldata author,
        uint publishedDate,
        string calldata notes
    )
    external
    isLibrarian
    isOperational
    bookExists(title, author, publishedDate)
    {
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        require(
            !libraryData.isCheckedOut(bookKey),
            "This book is already checked out"
        );
        libraryData.checkOutBook(borrower, bookKey, notes);
        emit BookCheckedOut(
            borrower,
            title,
            author,
            publishedDate
        );
    }

    function checkInBook
    (
        string calldata title,
        string calldata author,
        uint publishedDate,
        string calldata notes
    )
    external
    isOperational
    bookExists(title, author, publishedDate)
    {
        // anyone except librarians can check in books
        require(
            !libraryData.isRegistered(msg.sender),
            "Librarians cannot bring back books"
        );
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        require(
            libraryData.isCheckedOut(bookKey),
            "This book is already checked in"
        );
        libraryData.checkInBook(bookKey, notes, msg.sender);
        emit BookCheckedIn(
            title,
            author,
            publishedDate,
            libraryData.getBookOriginLibrarian(bookKey)
        );

    }

    function getBook
    (
        string calldata title,
        string calldata author,
        uint publishedDate
    )
    external
    view
    returns
    (
        /* title, author and publishedDate are not returned:
        they are already provided as params so they are well know
        by the caller. Moreover otherwise CompileError: stack is too deep
        */
        address originLibrarian,
        address currentOwner,
        bool checkedOut,
        uint transfersCount,
        address lastTransferFrom,
        string memory lastTransferNotes,
        uint price
    )
    {
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        originLibrarian = libraryData.getBookOriginLibrarian(bookKey);
        currentOwner = libraryData.getBookOwner(bookKey);
        checkedOut = libraryData.isCheckedOut(bookKey);
        transfersCount = libraryData.getTransfersCount(bookKey);
        (lastTransferFrom, lastTransferNotes) = libraryData.getTransfer(bookKey, transfersCount.sub(1));
        price = libraryData.getBookPrice(bookKey);
    }

    function sellBook
    (
        string calldata title,
        string calldata author,
        uint publishedDate,
        uint price,
        string calldata notes
    )
    external
    bookExists(title, author, publishedDate)
    isOperational
    {
        require(price > 0, "Sale price must be > 0");
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        require(
            libraryData.getBookOwner(bookKey) == msg.sender,
            "You cannot sale a book you do not own"
        );
        libraryData.sellBook(bookKey, price, msg.sender, notes);
        emit BookPutOnSale(
            title,
            author,
            publishedDate,
            price
        );
    }

    function buyBook
    (
        string calldata title,
        string calldata author,
        uint publishedDate
    )
    external
    isOperational
    payable
    {
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        uint price = libraryData.getBookPrice(bookKey);
        require(
            libraryData.getBookPrice(bookKey) > 0,
            "This book is not for sale"
        );
        require(msg.value >= price, "Funds sent do not cover the book price");

        // refund if funds sent too high
        uint amountToReturn = msg.value - price;
        msg.sender.transfer(amountToReturn);

        libraryData.buyBook.value(msg.value)(bookKey, msg.sender);
        emit BookSold(title, author, publishedDate, price);
    }

    function withdraw()
    external
    isOperational
    {
        libraryData.withdraw(msg.sender);
        emit Paid(msg.sender);
    }

}
