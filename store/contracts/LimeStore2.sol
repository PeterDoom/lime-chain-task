// SPDX-License-Identifier: MIT

//TODO Add GetAllTransactionsMethod + Finish Refund

pragma solidity ^0.8.0;
import "./Ownable.sol";

contract LimeStore is Ownable {
    address payable public storeAddress = payable(address(this));
    uint public storeBalance = 0;

    struct Product {
        uint256 id;
        string productName;
        uint256 productPrice;
        address currentOwner;
    }

    mapping(uint256 => Product) private products;
    mapping(string => bool) private productExists;
    mapping(uint256 => uint256) private productQuantities;
    uint256[] keys;

    struct Transaction {
        address owner;
        address previousOwner;
        uint256 productId;
        uint256 pricePaid;
        uint productQuantity;
    }

    mapping(uint256 => Transaction) private transactions;
    uint256[] transactionKeys;

    struct Customer {
        address customerWallet;
    }

    mapping(address => Customer) private previousCustomers;
    mapping(address => Transaction[]) private customerTransactions;
    address [] private customerKeys;



    function listProducts() external view returns (uint256[] memory id, Product[] memory productDescription)
    {
        Product[] memory productsAvailable = new Product[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            productsAvailable[i] = (products[keys[i]]);
        }

        return (keys, productsAvailable);
    }

    function purchase(uint productId, uint quantity) external payable {
        require(checkIfIdExists(keys, productId), "Product Doesn't exist");
        require(quantity >= 0, "Quantity must be bigger than 0");
        require(productQuantities[productId] >= quantity, "We don't have that much in stock");
        require(products[productId].productPrice <= msg.value, "Not enough money!");
        
        if (doesCustomerExist(customerKeys, msg.sender)){
            require(!isProductBought(customerTransactions[msg.sender], productId), "Product is already purchased");
            
            Transaction memory newTransaction = initiateTransaction(products[productId], quantity, msg.sender);
            customerTransactions[msg.sender].push(newTransaction);

            handleInvetory(productId, quantity, "dec");

            (bool isSuccessful, ) = storeAddress.call(
            abi.encodeWithSignature("transferTo(address)", "call transferTo", msg.sender)
            );

            storeBalance+= msg.value;

        } else {
            Customer memory newCustomer = createCustomer(msg.sender);
            previousCustomers[newCustomer.customerWallet] = newCustomer;
            customerKeys.push(newCustomer.customerWallet);

            Transaction memory newTransaction = initiateTransaction(products[productId], quantity, msg.sender);
            customerTransactions[msg.sender].push(newTransaction);

            handleInvetory(productId, quantity, "dec");

            (bool isSuccessful, ) = storeAddress.call(
            abi.encodeWithSignature("transferTo(address)", "call transferTo", msg.sender)
        );  

            storeBalance+= msg.value;
        }

    }

    function refund(uint productId) external payable {
        require(block.number <= 100, "Refund Time expired");
    }

    function addItem(uint256 productId, string memory productName, uint256 productPrice, uint256 productQuantity) external isOwner {
        require(!productExists[productName], "Product Exists");
        require(productQuantity > 0, "Product Quantity must be bigger than 0");
        require(!checkIfIdExists(keys, productId), "Id exists");

        Product memory product = Product(
            productId,
            productName,
            productPrice,
            address(this)
        );

        keys.push(product.id);
        products[product.id] = product;
        productExists[product.productName] = true;
        productQuantities[product.id] = productQuantity;
    }

    function checkIfIdExists(uint256[] memory _keys, uint256 idToCheck) private pure returns (bool)
    {
        for (uint256 i = 0; i < _keys.length; i++) {
            if (_keys[i] == idToCheck) {
                return true;
            }
        }

        return false;
    }

    function doesCustomerExist(address[] memory _customerKeys, address customerAddress) private pure returns (bool) {
        for (uint i=0; i< _customerKeys.length; i++) {
            if (customerAddress == _customerKeys[i]) {
                return true;
            }
        } 
        return false;
    }

    function isProductBought(Transaction[] memory _transactionsList, uint productId) private pure returns (bool){
        for(uint i=0; 1< _transactionsList.length; i++) {
            if (productId == _transactionsList[i].productId){
                return true;
            }
        }
        return false;
    }

    function initiateTransaction(Product memory product, uint productQuantity ,address customerAddress) private pure returns (Transaction memory transaction) {
             Transaction memory _transaction = Transaction(
                product.currentOwner,
                customerAddress,
                product.id,
                product.productPrice,
                productQuantity
            );

            return _transaction;
    }

    function createCustomer(address customerAddress) private pure returns(Customer memory customer) {
        Customer memory _customer = Customer(
            customerAddress
        );

        return _customer;
    }

    function handleInvetory(uint productId, uint productQuantity, string memory action) private {

        if (keccak256(abi.encodePacked((action))) == keccak256(abi.encodePacked(("inc")))) {
            productQuantities[productId] += productQuantity;

        } else if (keccak256(abi.encodePacked((action))) == keccak256(abi.encodePacked(("dec")))){
            productQuantities[productId] -= productQuantity;
        }

    }
}
