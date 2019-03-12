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

    function libraryOwner() external view returns(address);
    function isRegistered(address librarian) external view returns(bool);
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

    // modifier isNotBookOwner(address reader) {
    //     require(
    //         libraryData.isRegistered(librarian),
    //         "Must be registered as librarian to perform this action"
    //     );
    //     _;
    // }

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
    {
        bytes32 bookKey = getBookKey(title, author, publishedDate);
        libraryData.deleteBook(bookKey);
        emit BookDeleted(title, author, publishedDate);
    }

    // function getBook
    // (
    //
    // )

    // function checkBookToAddress(address reader)
    // isLibraryOwner
    // isOperational
    // isNotBookOwner
    // {
    //
    // }

}
