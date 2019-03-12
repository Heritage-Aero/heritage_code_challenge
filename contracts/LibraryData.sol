pragma solidity ^0.5.0;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract LibraryData {
    using SafeMath for uint;

    // ----------------- VARIABLES
    address private libraryOwner;

    // To track registered librarians
    mapping(address => bool) public librarians;

    struct Book {
        string title;
        string author;
        uint publishedDate;
        address currentOwner;
        address[] previousOwners;
        // notes will be used to track repairs and damages
        string[] notes;
        // ownerships will be used to count the number of successive owners
        uint ownerships;
        // price?
        // uint price;
    }

    /* Track all books in library
    key = hash(title, author, publishedDate)
    */
    mapping(bytes32 => Book) public lib;


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

    // ----------------- SMART CONTRACT CORE FUNCTIONS
    // Add or remove (depending on add arg)
    function setMembership(address librarian, bool add)
    external
    callerAuthorized
    isOperational
    {
        librarians[librarian] = add;
    }
}
