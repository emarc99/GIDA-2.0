#[starknet::contract]
mod Bookstore {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage_access::StorageAccess;
    use option::OptionTrait;
    use traits::Into;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        books: LegacyMap<felt252, Book>,  // ISBN as key
        book_count: u32
    }

    #[derive(Drop, Serde)]
    struct Book {
        title: felt252,
        author: felt252,
        description: felt252,
        price: u16,
        quantity: u8,
        isbn: felt252
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BookAdded: BookAdded,
        BookUpdated: BookUpdated,
        BookRemoved: BookRemoved
    }

    #[derive(Drop, starknet::Event)]
    struct BookAdded {
        isbn: felt252,
        title: felt252,
        price: u16
    }

    #[derive(Drop, starknet::Event)]
    struct BookUpdated {
        isbn: felt252,
        new_price: u16,
        new_quantity: u8
    }

    #[derive(Drop, starknet::Event)]
    struct BookRemoved {
        isbn: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[external(v0)]
    impl BookstoreImpl of super::IBookstore {
        fn add_book(
            ref self: ContractState,
            title: felt252,
            author: felt252,
            description: felt252,
            price: u16,
            quantity: u8,
            isbn: felt252
        ) {
            self.only_owner();

            let book = Book {
                title,
                author,
                description,
                price,
                quantity,
                isbn
            };

            self.books.write(isbn, book);
            self.book_count.write(self.book_count.read() + 1);

            self.emit(Event::BookAdded(BookAdded { isbn, title, price }));
        }

        fn update_book(
            ref self: ContractState,
            isbn: felt252,
            new_price: u16,
            new_quantity: u8
        ) {
            self.only_owner();
            
            let mut book = self.books.read(isbn);
            book.price = new_price;
            book.quantity = new_quantity;
            
            self.books.write(isbn, book);
            self.emit(Event::BookUpdated(BookUpdated { isbn, new_price, new_quantity }));
        }

        fn remove_book(ref self: ContractState, isbn: felt252) {
            self.only_owner();
            
            self.books.write(isbn, Option::None(()));
            self.book_count.write(self.book_count.read() - 1);
            
            self.emit(Event::BookRemoved(BookRemoved { isbn }));
        }

        fn get_book(self: @ContractState, isbn: felt252) -> Book {
            self.books.read(isbn)
        }

        fn get_book_count(self: @ContractState) -> u32 {
            self.book_count.read()
        }
    }

    #[starknet::interface]
    trait IBookstore<TContractState> {
        fn add_book(
            ref self: TContractState,
            title: felt252,
            author: felt252,
            description: felt252,
            price: u16,
            quantity: u8,
            isbn: felt252
        );
        fn update_book(ref self: TContractState, isbn: felt252, new_price: u16, new_quantity: u8);
        fn remove_book(ref self: TContractState, isbn: felt252);
        fn get_book(self: @TContractState, isbn: felt252) -> Book;
        fn get_book_count(self: @TContractState) -> u32;
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn only_owner(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
        }
    }
}
