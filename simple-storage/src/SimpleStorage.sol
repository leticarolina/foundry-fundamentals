//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract SimpleStorage {
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] public listOfPeople;

    // Declare a mapping that links a keyType name (string) to a value: favorite number (uint256)
    //syntax mapping(key -> type) visibility mappingName;
    mapping(string => uint256) public giveNameGetFavoriteNumber;

    //function to add a new person to the list and update the mapping
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // Add a new Person struct to the array with the provided name and favorite number
        listOfPeople.push(Person(_favoriteNumber, _name));

        // Update the mapping with the person's name as the key and their favorite number as the value
        giveNameGetFavoriteNumber[_name] = _favoriteNumber;
    }

    function getPerson(
        uint256 index
    ) public view returns (uint256, string memory) {
        Person memory person = listOfPeople[index];
        return (person.favoriteNumber, person.name);
    }
}
