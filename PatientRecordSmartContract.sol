// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PatientRecordContract {
    address public owner;
    uint public totalRecords = 0;

    struct Patient {
        string name;
        uint age;
        string sex;
        string mobile;
        string diagnosis;
        string treatment;
        address currentProvider;
        uint createdAt;       // Timestamp when added
        uint lastUpdated;     // Timestamp when last updated
    }

    mapping(uint => Patient) public records;
    mapping(address => bool) public authorisedProviders;
    uint[] public recordIds;

    // Events
    event ProviderAuthorised(address provider);
    event ProviderRevoked(address provider);
    event PatientRecordAdded(uint recordId, address provider, uint timestamp);
    event PatientRecordUpdated(uint recordId, address provider, uint timestamp);
    event RecordTransferred(uint recordId, address fromProvider, address toProvider);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorised() {
        require(authorisedProviders[msg.sender], "Not an authorised provider");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        authorisedProviders[msg.sender] = true;
    }

    // Authorisation functions
    function authoriseProvider(address provider) public onlyOwner {
        authorisedProviders[provider] = true;
        emit ProviderAuthorised(provider);
    }

    function revokeProvider(address provider) public onlyOwner {
        authorisedProviders[provider] = false;
        emit ProviderRevoked(provider);
    }

    // Add new patient record
    function addPatientRecord(
        string memory _name,
        uint _age,
        string memory _sex,
        string memory _mobile,
        string memory _diagnosis,
        string memory _treatment
    ) public onlyAuthorised {
        totalRecords++;
        uint currentTime = block.timestamp;
        records[totalRecords] = Patient(
            _name,
            _age,
            _sex,
            _mobile,
            _diagnosis,
            _treatment,
            msg.sender,
            currentTime,
            currentTime
        );
        recordIds.push(totalRecords);
        emit PatientRecordAdded(totalRecords, msg.sender, currentTime);
    }

    // Update an existing patient record
    function updatePatientRecord(
        uint recordId,
        string memory _name,
        uint _age,
        string memory _sex,
        string memory _mobile,
        string memory _diagnosis,
        string memory _treatment
    ) public onlyAuthorised {
        require(records[recordId].currentProvider == msg.sender, "Only the current provider can update");

        Patient storage p = records[recordId];
        p.name = _name;
        p.age = _age;
        p.sex = _sex;
        p.mobile = _mobile;
        p.diagnosis = _diagnosis;
        p.treatment = _treatment;
        p.lastUpdated = block.timestamp;

        emit PatientRecordUpdated(recordId, msg.sender, block.timestamp);
    }

    // Transfer a patient record to another authorised provider
    function transferRecord(uint recordId, address toProvider) public onlyAuthorised {
        require(authorisedProviders[toProvider], "Target provider is not authorised");
        require(records[recordId].currentProvider == msg.sender, "Only current provider can transfer");

        address previous = records[recordId].currentProvider;
        records[recordId].currentProvider = toProvider;

        emit RecordTransferred(recordId, previous, toProvider);
    }

    // Retrieve full patient record
    function getPatientRecord(uint recordId) public view onlyAuthorised returns (
        string memory name,
        uint age,
        string memory sex,
        string memory mobile,
        string memory diagnosis,
        string memory treatment,
        address currentProvider,
        uint createdAt,
        uint lastUpdated
    ) {
        Patient memory p = records[recordId];
        return (
            p.name,
            p.age,
            p.sex,
            p.mobile,
            p.diagnosis,
            p.treatment,
            p.currentProvider,
            p.createdAt,
            p.lastUpdated
        );
    }

    // Get all record IDs
    function getAllRecordIds() public view onlyAuthorised returns (uint[] memory) {
        return recordIds;
    }

    // Get records by provider
    function getRecordsByProvider(address provider) public view onlyAuthorised returns (uint[] memory) {
        uint count = 0;
        for (uint i = 0; i < recordIds.length; i++) {
            if (records[recordIds[i]].currentProvider == provider) {
                count++;
            }
        }

        uint[] memory result = new uint[](count);
        uint j = 0;
        for (uint i = 0; i < recordIds.length; i++) {
            if (records[recordIds[i]].currentProvider == provider) {
                result[j] = recordIds[i];
                j++;
            }
        }

        return result;
    }
}

