public class DummyJsonUser {
    public String id;
    public String firstName;
    public String lastName;
    public String email;
    public String phone;
    public Date birthDate;
    public DummyJsonUserAddress address;

    public class DummyJsonUserAddress {
        public String address;
        public String city;
        public String postalCode;
        public String state;
        public String country;
    }

}