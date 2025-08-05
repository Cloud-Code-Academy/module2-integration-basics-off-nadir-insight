public class DummyJsonUser {
    public DummyJsonUser(String id, String firstName, String lastName, String email, String phone) {
        this.salesforceId = id;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phone = phone;
    }
    public String id;
    public String salesforceId;
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