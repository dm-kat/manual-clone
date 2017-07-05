require 'spec_helper'

describe Gitlab::LDAP::Person do
  include LdapHelpers

  let(:entry) { ldap_user_entry('john.doe') }

  it 'includes the EE module' do
    expect(described_class).to include(EE::Gitlab::LDAP::Person)
  end

  describe '.find_by_email' do
    let(:adapter) { ldap_adapter }

    it 'tries finding for each configured email attribute' do
      expect(adapter).to receive(:user).with('mail', 'jane@gitlab.com')
      expect(adapter).to receive(:user).with('email', 'jane@gitlab.com')
      expect(adapter).to receive(:user).with('userPrincipalName', 'jane@gitlab.com')

      described_class.find_by_email('jane@gitlab.com', adapter)
    end

    it 'returns nil when no user was found' do
      allow(adapter).to receive(:user)

      found_user = described_class.find_by_email('jane@gitlab.com', adapter)

      expect(found_user).to eq(nil)
    end
  end

  describe '#kerberos_principal' do
    let(:entry) do
      ldif = "dn: cn=foo, dc=bar, dc=com\n"
      ldif += "sAMAccountName: #{sam_account_name}\n" if sam_account_name
      Net::LDAP::Entry.from_single_ldif_string(ldif)
    end

    subject { described_class.new(entry, 'ldapmain') }

    context 'when sAMAccountName is not defined (non-AD LDAP server)' do
      let(:sam_account_name) { nil }

      it 'returns nil' do
        expect(subject.kerberos_principal).to be_nil
      end
    end

    context 'when sAMAccountName is defined (AD server)' do
      let(:sam_account_name) { 'mylogin' }

      it 'returns the principal combining sAMAccountName and DC components of the distinguishedName' do
        expect(subject.kerberos_principal).to eq('mylogin@BAR.COM')
      end
    end
  end

  describe '#ssh_keys' do
    let(:ssh_key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrSQHff6a1rMqBdHFt+FwIbytMZ+hJKN3KLkTtOWtSvNIriGhnTdn4rs+tjD/w+z+revytyWnMDM9dS7J8vQi006B16+hc9Xf82crqRoPRDnBytgAFFQY1G/55ql2zdfsC5yvpDOFzuwIJq5dNGsojS82t6HNmmKPq130fzsenFnj5v1pl3OJvk513oduUyKiZBGTroWTn7H/eOPtu7s9MD7pAdEjqYKFLeaKmyidiLmLqQlCRj3Tl2U9oyFg4PYNc0bL5FZJ/Z6t0Ds3i/a2RanQiKxrvgu3GSnUKMx7WIX373baL4jeM7cprRGiOY/1NcS+1cAjfJ8oaxQF/1dYj' }
    let(:ssh_key_attribute_name) { 'altSecurityIdentities' }
    let(:entry) do
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{keys}")
    end

    subject { described_class.new(entry, 'ldapmain') }

    before do
      allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(sync_ssh_keys: ssh_key_attribute_name)
    end

    context 'when the SSH key is literal' do
      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key}" }

      it 'includes the SSH key' do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context 'when the SSH key is prefixed' do
      let(:keys) { "#{ssh_key_attribute_name}: SSHKey:#{ssh_key}" }

      it 'includes the SSH key' do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context 'when the SSH key is suffixed' do
      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key} (SSH key)" }

      it 'includes the SSH key' do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context 'when the SSH key is followed by a newline' do
      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key}\n" }

      it 'includes the SSH key' do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context 'when the key is not an SSH key' do
      let(:keys) { "#{ssh_key_attribute_name}: KerberosKey:bogus" }

      it 'is empty' do
        expect(subject.ssh_keys).to be_empty
      end
    end

    context 'when there are multiple keys' do
      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key}\n#{ssh_key_attribute_name}: KerberosKey:bogus\n#{ssh_key_attribute_name}: ssh-rsa keykeykey" }

      it 'includes both SSH keys' do
        expect(subject.ssh_keys).to include(ssh_key)
        expect(subject.ssh_keys).to include('ssh-rsa keykeykey')
        expect(subject.ssh_keys).not_to include('KerberosKey:bogus')
      end
    end
  end

  describe '#memberof' do
    it 'returns an empty array if the field was not present' do
      person = described_class.new(entry, 'ldapmain')

      expect(person.memberof).to eq([])
    end

    it 'returns the values of `memberof` if the field was present' do
      example_memberof = ['CN=Group Policy Creator Owners,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Domain Admins,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Enterprise Admins,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Schema Admins,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Administrators,CN=Builtin,DC=Vosmaer,DC=com']
      entry['memberof'] = example_memberof
      person = described_class.new(entry, 'ldapmain')

      expect(person.memberof).to eq(example_memberof)
    end
  end

  describe '#cn_from_memberof' do
    it 'gets the group cn from the memberof value' do
      person = described_class.new(entry, 'ldapmain')

      expect(person.cn_from_memberof('cN=Group Policy Creator Owners,CN=Users,DC=Vosmaer,DC=com'))
        .to eq('Group Policy Creator Owners')
    end

    it "doesn't break when there is no CN property" do
      person = described_class.new(entry, 'ldapmain')

      expect(person.cn_from_memberof('DC=Vosmaer,DC=com'))
        .to be_nil
    end
  end

  describe '#group_cns' do
    it 'returns only CNs from the memberof values' do
      example_memberof = ['CN=Group Policy Creator Owners,CN=Users,DC=Vosmaer,DC=com',
                          'CN=Administrators,CN=Builtin,DC=Vosmaer,DC=com']
      entry['memberof'] = example_memberof
      person = described_class.new(entry, 'ldapmain')

      expect(person.group_cns).to eq(['Group Policy Creator Owners', 'Administrators'])
    end
  end
end
