#[starknet::contract]
mod Purchase {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage_access::StorageAccess;
    use option::OptionTrait;

    #[storage]
    struct Storage {
        bookstore: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BookPurchased: BookPurchased
    }

    #[derive(Drop, starknet::Event)]
    struct BookPurchased {
        buyer: ContractAddress,
        isbn: felt252,
        quantity: u8,
        total_price: u16
    }

    #[constructor]
    fn constructor(ref self: ContractState, bookstore: ContractAddress) {
        self.bookstore.write(bookstore);
    }

    #[external(v0)]
    impl PurchaseImpl of super::IPurchase {
        fn buy_book(ref self: ContractState, isbn: felt252, quantity: u8) {
            let caller = get_caller_address();
            
            // Get book details from Bookstore contract
            let book = self.get_book_from_store(isbn);
            
            // Validate quantity
            assert(quantity > 0, 'Quantity must be positive');
            assert(quantity <= book.quantity, 'Not enough stock');
            
            // Calculate total price
            let total_price = book.price * quantity.into();
            
            // In a real implementation, you would handle payment here
            
            // Update book quantity in Bookstore contract
            let new_quantity = book.quantity - quantity;
            self.update_book_in_store(isbn, book.price, new_quantity);
            
            self.emit(Event::BookPurchased(BookPurchased {
                buyer: caller,
                isbn,
                quantity,
                total_price
            }));
        }

        fn set_bookstore(ref self: ContractState, new_bookstore: ContractAddress) {
            self.bookstore.write(new_bookstore);
        }
    }

    #[starknet::interface]
    trait IPurchase<TContractState> {
        fn buy_book(ref self: TContractState, isbn: felt252, quantity: u8);
        fn set_bookstore(ref self: TContractState, new_bookstore: ContractAddress);
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_book_from_store(self: @ContractState, isbn: felt252) -> super::Bookstore::Book {
            let bookstore = self.bookstore.read();
            let book = IBookstoreDispatcher { contract_address: bookstore }.get_book(isbn);
            book
        }

        fn update_book_in_store(ref self: ContractState, isbn: felt252, price: u16, quantity: u8) {
            let bookstore = self.bookstore.read();
            IBookstoreDispatcher { contract_address: bookstore }.update_book(isbn, price, quantity);
        }
    }
}
