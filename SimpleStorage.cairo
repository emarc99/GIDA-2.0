#[starknet::contract]
mod StudentStorage {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage_access::StorageAccess;

    #[storage]
    struct Storage {
        name: felt252,
        age: u8
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StudentUpdated: StudentUpdated
    }

    #[derive(Drop, starknet::Event)]
    struct StudentUpdated {
        old_name: felt252,
        new_name: felt252,
        old_age: u8,
        new_age: u8
    }

    #[external(v0)]
    impl StudentStorageImpl of super::IStudentStorage {
        fn set_student(ref self: ContractState, name: felt252, age: u8) {
            let old_name = self.name.read();
            let old_age = self.age.read();
            
            self.name.write(name);
            self.age.write(age);
            
            self.emit(Event::StudentUpdated(StudentUpdated {
                old_name,
                new_name: name,
                old_age,
                new_age: age
            }));
        }

        fn get_student(self: @ContractState) -> (felt252, u8) {
            (self.name.read(), self.age.read())
        }
    }

    #[starknet::interface]
    trait IStudentStorage<TContractState> {
        fn set_student(ref self: TContractState, name: felt252, age: u8);
        fn get_student(self: @TContractState) -> (felt252, u8);
    }
}
