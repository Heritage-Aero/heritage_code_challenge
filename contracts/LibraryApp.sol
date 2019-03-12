pragma solidity ^0.5.0;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


// Interface contract
interface LibraryData {
    function setMembership(address librarian, bool add) external;
    function libraryOwner() external view returns(address);
    function isRegistered(address librarian) external view returns(bool);
}


contract LibraryApp {
    using SafeMath for uint;

    // ----------------- VARIABLES
    LibraryData libraryData;
    address appOwner;
    bool public operational = false;
    // ----------------- EVENTS

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
    modifier isRegistered(address librarian) {
        require(
            libraryData.isRegistered(librarian),
            "Must be registered as librarian to perform this action"
        );
        _;
    }

    // ----------------- HELPERS FUNCTIONS

    // ----------------- SMART CONTRACT FUNCTIONS
    function setMembership(address librarian, bool add)
    external
    isLibraryOwner
    isOperational
    differentMembershipRequest(librarian, add)
    {
        libraryData.setMembership(librarian, add);
    }

}
