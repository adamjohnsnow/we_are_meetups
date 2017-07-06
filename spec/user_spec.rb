
describe User do

  context 'user creation' do

    it 'create user' do
      User.create("Firstname", "Surname", "email@email.com", "password")
      expect(User.all.count).to eq 1
    end

    it 'no duplicate user' do
      User.create("Firstname", "Surname", "email@email.com", "password")
      expect(User.all.count).to eq 1
    end

    it 'add second user' do
      User.create("Firstname", "Surname", "email2@email.com", "password")
      expect(User.all.count).to eq 2
    end

    it { expect(User.first.firstname).to eq "Firstname" }

    it { expect(User.first.surname).to eq "Surname" }

    it { expect(User.first.email).to eq "email@email.com" }

  end

  context 'user log in' do

    it 'can log in' do
      user = User.login({ email: 'email@email.com', password: 'password' })
      expect(user.firstname).to eq 'Firstname'
    end

    it 'log in fail' do
      user = User.login({ email: 'email@email.com', password: 'wrong' })
      expect(user).to eq nil
    end
  end
end
