# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Calculate conditional actions', type: :model do
  include ModelSupport
  include ActivityLogSupport

  def setup_config(confy)
    config = YAML.safe_load(confy).deep_symbolize_keys
    @al.reset_model_references
    config
  end

  before :example do
    u1, = create_user
    @u1 = u1
    create_user
    create_master
    let_user_create_player_contacts

    setup_access :activity_log__player_contact_phones
    setup_access :addresses
    setup_access :activity_log__player_contact_phone__primary
    setup_access :activity_log__player_contact_phone__blank

    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type, user: @user

    @al2 = create_item
    @al0 = create_item
    @al = create_item

    @al0.master_id = @al.master_id
    @al0.force_save!
    @al0.save!

    @al2.master_id = @al.master_id
    @al2.select_who += '-alt'
    @al2.force_save!
    @al2.save!

    n = Admin::UserRole.order(id: :desc).limit(1).pluck(:id).first
    Admin::UserRole.where(role_name: 'test', app_type: u1.app_type).update_all(role_name: "test-old-#{n}")
    Admin::UserRole.create! app_type: u1.app_type, user: u1, role_name: 'test', current_admin: @admin
    Admin::UserRole.create! app_type: u1.app_type, user: @user, role_name: 'test', current_admin: @admin

    # The number of roles is one more than we added due to automatic setup of a template@template item
    expect(Admin::UserRole.where(role_name: 'test', app_type: u1.app_type).count).to eq 3

    @role_user_ids = [u1.id, @user.id]
  end

  it 'always returns false for never and true for always' do
    conf = { never: true }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = { always: true }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true
  end

  it 'checks if all attributes have a certain value' do
    conf = {
      all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        this: {
          select_who: 'will not work',
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      all: {
        this: {
          select_who: @al.select_who,
          user_id: -1
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      all: {
        this: {
          select_who: 'will not work',
          user_id: -1
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    # Check that an array of possible values evaluates correctly

    conf = {
      all: {
        this: {
          select_who: ["doesn't match", @al.select_who],
          user_id: [@al.user_id, "doesn't match"]
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true
  end

  it 'checks if any attributes have a certain value' do
    conf = {
      any: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      any: {
        this: {
          select_who: 'will not work',
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      any: {
        this: {
          select_who: @al.select_who,
          user_id: -1
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      any: {
        this: {
          select_who: 'will not work',
          user_id: -1
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false
  end

  it 'checks if none of the attributes have a certain value' do
    conf = {
      not_any: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      not_any: {
        this: {
          select_who: 'will not work',
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      not_any: {
        this: {
          select_who: @al.select_who,
          user_id: -1
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      not_any: {
        this: {
          select_who: 'will not work',
          user_id: -1
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true
  end

  it 'checks if not all the attributes have a certain value' do
    conf = {
      not_all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      not_all: {
        this: {
          select_who: 'will not work',
          user_id: @al.user_id
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      not_all: {
        this: {
          select_who: @al.select_who,
          user_id: -1
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      not_all: {
        this: {
          select_who: 'will not work',
          user_id: -1
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true
  end

  it 'checks if all attributes in this and another table in the master have a certain value' do
    m = @al.master
    m.current_user = @user
    @pc = m.player_contacts.create! data: '(516)123-7612', rec_type: 'phone', rank: 10, source: 'nflpa'

    conf = {
      all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        },
        player_contacts: {
          data: @pc.data
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        this: {
          select_who: 'should fail',
          user_id: @al.user_id
        },
        player_contacts: {
          data: @pc.data
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        },
        player_contacts: {
          data: '0001112223'
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false
  end

  it 'checks if all attributes match multiple condition types' do
    m = @al.master
    m.current_user = @user
    @pc = m.player_contacts.create! data: '(516)123-7612', rec_type: 'phone', rank: 10, source: 'nflpa'

    conf = {
      all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        },
        player_contacts: {
          data: @pc.data
        }
      },
      not_any: {
        player_contacts: {
          data: 'not this'
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        },
        player_contacts: {
          data: @pc.data
        }
      },
      not_any: {
        player_contacts: {
          data: @pc.data
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false
  end

  it 'checks for lists of possible items in the the same table with different sets of attributes' do
    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: 'Portland',
                             state: 'OR',\
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 0,
                             rec_type: 'home',
                             source: 'nflpa'

    m.addresses.create! city: 'Portland',
                        state: 'OR',
                        zip: rand(99_999).to_s.rjust(5, '0').to_s,
                        rank: 10,
                        rec_type: 'home',
                        source: 'nflpa'

    conf = {
      any: [
        {
          addresses: {
            zip: a1.zip
          }
        },
        {
          addresses: {
            zip: 'x'
          }
        }
      ]
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      any: [
        {
          addresses: {
            zip: 'x'
          }
        },
        {
          addresses: {
            zip: 'x'
          }
        }
      ]
    }
    res = ConditionalActions.new conf, @al

    expect(res.calc_action_if).to be false
  end

  it 'checks if nested conditions work' do
    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 0,
                             rec_type: 'home',
                             source: 'nflpa'

    a2 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 10,
                             rec_type: 'home',
                             source: 'nflpa'

    @pc = m.player_contacts.create! data: '(516)123-7612', rec_type: 'phone', rank: 10, source: 'nflpa'

    conf = {
      all: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id
          },
          addresses: {
            id: a2.id,
            zip: [a1.zip, a2.zip]
          }
        },
        not_all: {
          addresses: {
            id: a1.id,
            zip: 'x'
          }
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id
          }
        },
        any: [
          all: {
            addresses: {
              id: a1.id,
              zip: a1.zip
            }
          },
          all_2: {
            addresses: {
              id: a2.id,
              zip: a1.zip
            }
          }
        ]
      }
    }
    res = ConditionalActions.new conf, @al

    expect(res.calc_action_if).to be true

    # This form has an unnecessary this: at the second level but possibly appears in older configurations
    conf = {
      all: {
        this: {
          all: {
            this: {
              select_who: @al.select_who,
              user_id: @al.user_id
            }
          },
          any: [
            all: {
              addresses: {
                id: a1.id,
                zip: 'x'
              }
            },
            all_2: {
              addresses: {
                id: a2.id,
                zip: 'x'
              }
            }
          ]
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # This form is the same as the previous example without the unnecessary this: at the second level
    conf = {
      all: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id
          }
        },
        any: [
          all: {
            addresses: {
              id: a1.id,
              zip: 'x'
            }
          },
          all_2: {
            addresses: {
              id: a2.id,
              zip: 'x'
            }
          }
        ]
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      not_all: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id
          }
        },
        any: [
          all: {
            addresses: {
              id: a1.id,
              zip: 'x'
            }
          },
          all_2: {
            addresses: {
              id: a2.id,
              zip: 'x'
            }
          }
        ]
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      not_any: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id
          }
        },
        any: [
          all: {
            addresses: {
              id: a1.id,
              zip: 'x'
            }
          },
          all_2: {
            addresses: {
              id: a2.id,
              zip: 'x'
            }
          }
        ]
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      not_any: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: -1
          }
        },
        any: [
          all: {
            addresses: {
              id: a1.id,
              zip: 'x'
            }
          },
          all_2: {
            addresses: {
              id: a2.id,
              zip: 'x'
            }
          }
        ]
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    # Check that nested conditions work across various tables

    conf = {
      all: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id
          },
          addresses: {
            id: a2.id,
            zip: [a1.zip, a2.zip]
          }
        },
        not_all: {
          player_contacts: {
            data: @pc.data
          }
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      all: {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id
          },
          addresses: {
            id: a2.id,
            zip: [a1.zip, a2.zip]
          }
        },
        not_all: {
          player_contacts: {
            data: @pc.data + '-bad'
          }
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {

      all: {
        this: {
          select_who: @al.select_who,
          user_id: @al.user_id
        },
        addresses: {
          id: a2.id,
          zip: [a1.zip, a2.zip]
        }
      },
      not_all: {
        all:
          [
            {
              player_contacts: {
                data: @pc.data
              }
            },
            {
              player_contacts: {
                id: @pc.id
              }
            }
          ]

      }

    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Deep nesting
    conf = {
      # Negate the nested result
      not_all_dms: {
        all_pcs: {

          any: {
            # A player contact record exists in the master
            player_contacts: {
              id: @pc.id
            }

          },

          # A player contact record exists in the master
          all_pcs_with_data: {
            player_contacts: {
              id: @pc.id,
              data: @pc.data
            }
          }
        }
      }

    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Need all: before named table
    conf = {
      # Negate the nested result
      not_all_dms: {
        all_pcs: {

          any: {
            # A player contact record exists in the master
            player_contacts: {
              id: @pc.id
            }

          },

          # A player contact record exists in the master
          #          all_pcs_with_data: {
          player_contacts: {
            id: @pc.id,
            data: @pc.data
          }
          #          }
        }
      }

    }

    res = ConditionalActions.new conf, @al
    expect do
      res.calc_action_if
    end.to raise_error FphsException

    # Need all: before named table
    conf = {
      # Negate the nested result
      not_all_dms: {
        any_pcs: {

          any: {
            # A player contact record exists in the master
            player_contacts: {
              id: 0
            }

          },

          # A player contact record exists in the master
          #          all_pcs_with_data: {
          player_contacts: {
            id: @pc.id,
            data: @pc.data
          }
          #          }
        }
      }

    }

    res = ConditionalActions.new conf, @al
    expect do
      res.calc_action_if
    end.to raise_error FphsException

    # Check that calc_query_conditions handles nested any conditions OK
    conf = {

      any_pcs: {

        player_contacts: {
          id: @pc.id,
          data: @pc.data
        },

        any: {
          # A player contact record exists in the master
          player_contacts: {
            id: 0
          }

        }

      }

    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    # Check that calc_query_conditions handles nested any conditions OK
    conf = {

      any_pcs: {

        player_contacts: {
          id: -1,
          data: 'bad @pc.data'
        },

        any: {
          # A player contact record exists in the master
          player_contacts: {
            id: 0
          }

        }

      }

    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Check that calc_query_conditions handles nested any conditions OK
    conf = {

      all: {
        activity_log__player_contact_phones: {
          select_who: @al.select_who
        }
      },

      any_pcs: {
        all: {
          player_contacts: {
            data: 'not good'
          }
        },

        not_any: {
          # A player contact record exists in the master
          player_contacts: {
            id: @pc.id
          }

        }

      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Check that calc_query_conditions handles nested any conditions OK

    # Validate the first chunk
    conf = {

      all: {
        activity_log__player_contact_phones: {
          select_who: @al2.select_who
        },
        player_contacts: {
          data: @pc.data
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    # Validate the second chunk
    conf = {

      any_done: {
        all: {
          activity_log__player_contact_phones: {
            select_who: 'not good'
          }
        },

        not_any: {
          activity_log__player_contact_phones: {
            select_who: @al.select_who
          }

        }

      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Both chunks together
    conf = {

      all: {
        activity_log__player_contact_phones: {
          select_who: @al2.select_who
        },
        player_contacts: {
          data: @pc.data
        }
      },

      any_done: {
        all: {
          activity_log__player_contact_phones: {
            select_who: 'not good'
          }
        },

        not_any: {
          activity_log__player_contact_phones: {
            select_who: @al.select_who
          }

        }

      }
    }

    res = ConditionalActions.new conf, @al
    r = res.calc_action_if
    expect(r).to be false
  end

  describe 'checks against the current user' do
    it 'checks if a certain the current user has a specific id' do
      # user_id for the activity log matches the current user's id
      conf = {
        all_creator: {
          this: {
            user_id: {
              user: 'id'
            }
          }
        }
      }
      res = ConditionalActions.new conf, @al
      expect(res.calc_action_if).to be true

      conf = {
        all: {
          user: {
            id: {
              this: 'user_id'
            }
          }
        }
      }

      res = ConditionalActions.new conf, @al

      expect(res.calc_action_if).to eq true
    end

    it 'checks if the current user has a specific role' do
      al = create_item

      conf = {
        all: {
          user: {
            role_name: 'test-role'
          }
        }
      }

      res = ConditionalActions.new conf, al

      expect(res.calc_action_if).to be false

      Admin::UserRole.create! current_admin: @admin, role_name: 'test-role', app_type: @user.app_type, user: @user

      conf = {
        all: {
          user: {
            role_name: 'test-role'
          }
        }
      }

      res = ConditionalActions.new conf, al
      expect(res.calc_action_if).to be true

      conf = {
        all: {
          user: {
            role_name: %w[test-role x]
          }
        }
      }

      res = ConditionalActions.new conf, al
      expect(res.calc_action_if).to be true

      conf = {
        all: {
          user: {
            role_name: %w[y x]
          }
        }
      }

      res = ConditionalActions.new conf, al
      expect(res.calc_action_if).to be false

      # Check the user has a role matching the current instance attribute value

      expect(@user.role_names.first).not_to be nil
      conf = {
        all: {
          this: {
            select_who: {
              user: 'role_name'
            }
          }
        }
      }

      al.select_who = 'bad role'

      res = ConditionalActions.new conf, al
      expect(res.calc_action_if).to be false

      al.select_who = @user.role_names.first
      res = ConditionalActions.new conf, al
      expect(res.calc_action_if).to be true
    end
  end

  it 'allows any record that this one references to be used for conditions' do
    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 0,
                             rec_type: 'home',
                             source: 'nflpa'

    a2 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 10,
                             rec_type: 'home',
                             source: 'nflpa'

    @al.extra_log_type_config.references = {
      address: {
        address: {
          from: 'master',
          add: 'one_to_master'
        }
      },
      player_contact: {
        player_contact: {
          from: 'master',
          add: 'many'
        }
      }
    }

    ModelReference.create_with @al, a1, force_create: true
    ModelReference.create_with @al, a2, force_create: true

    expect(@al.model_references.length).to eq 2

    # Does the referenced item work correctly?

    confy = <<~EOF_YAML
      all:
        addresses:
          city: 'portland'
          zip: '#{a1.zip}'
          id:
            this_references: id
    EOF_YAML

    conf = setup_config(confy)

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    # Does a referenced item specifying a record type work correctly?

    confy = <<~EOF_YAML
      all:
        addresses:
          city: 'portland'
          zip: '#{a1.zip}'
          id:
            this_references:
              player_contact: id
    EOF_YAML

    conf = setup_config(confy)

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    confy = <<~EOF_YAML
      all:
        addresses:
          city: 'portland'
          zip: '#{a1.zip}'
          id:
            this_references:
              address: id
    EOF_YAML

    conf = setup_config(confy)

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    confy = <<~EOF_YAML
      all:
        addresses:
          city: 'portland'
          zip: '#{a1.zip}'
          rank:
            this_references:
              # This activity log references a address record with 'rank'
              # that matches an address with equal rank
              address: rank
    EOF_YAML

    conf = setup_config(confy)

    address_rank = @al.master.addresses.first.rank

    # expect(@al.master.addresses.pluck(:rank)).to include address_rank

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    # More complex references
    confy = <<~EOF_YAML
      all:
        activity_log__player_contact_phones:
          id: #{@al0.id}


        any:
          all:
            addresses:
              city: 'portland'
              zip: #{a1.zip}
              id:
                this_references: id


          all2:
            addresses:
              city: 'portland'
              zip: x
              id:
                this_references: id

      not_all:
        activity_log__player_contact_phones:
          extra_log_type: xxx
          id:
            this_references: id
    EOF_YAML

    conf = setup_config(confy)

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    confy = <<~EOF_YAML
      all:
        activity_log__player_contact_phones:
          id: #{@al0.id}


        any:
          all:
            addresses:
              city: 'portland'
              zip: x
              id:
                this_references: id


          all2:
            addresses:
              city: 'portland'
              zip: #{a1.zip}
              id:
                this_references: id

      not_all:
        activity_log__player_contact_phones:
          extra_log_type: xxx
          id:
            this_references: id
    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references
    res = ConditionalActions.new conf, @al

    expect(res.calc_action_if).to be true

    # Check nested alls work as expected
    confy = <<~EOF_YAML
      all:
        all:
          activity_log__player_contact_phones:
            id: #{@al0.id}


          any:
            all:
              addresses:
                city: 'portland'
                zip: x
                id:
                  this_references: id


            all2:
              addresses:
                city: 'portland'
                zip: #{a1.zip}
                id:
                  this_references: id

        not_all:
          activity_log__player_contact_phones:
            extra_log_type: xxx
            id:
              this_references: id
    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references

    res = ConditionalActions.new conf, @al

    expect(res.calc_action_if).to be true

    # # Try matching any across multiple relations
    m.player_contacts.create! rec_type: :phone, data: '(123)456-7891', rank: 5
    m.player_contacts.create! rec_type: :phone, data: '(123)456-7892', rank: 10
    # ModelReference.create_with @al, pc1
    # ModelReference.create_with @al, pc2
    #
    # expect(@al.model_references.length).to eq 4
  end

  it 'correctly joins in queries so that any / not_any work as expected' do
    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 0,
                             rec_type: 'home',
                             source: 'nflpa'

    a2 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 10,
                             rec_type: 'home',
                             source: 'nflpa'

    @al.extra_log_type_config.references = {
      address: {
        address: {
          from: 'master',
          add: 'one_to_master'
        }
      },
      player_contact: {
        player_contact: {
          from: 'master',
          add: 'many'
        }
      }
    }

    ModelReference.create_with @al, a1, force_create: true
    ModelReference.create_with @al, a2, force_create: true

    expect(@al.model_references.length).to eq 2

    confy = <<~EOF_YAML
      any:
          addresses:
            city: #{m.addresses.first.city}

          player_contacts:
            data: fake
    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be true

    confy = <<~EOF_YAML
      not_any:
          addresses:
            city: #{m.addresses.first.city}

          player_contacts:
            data: fake

    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be false

    confy = <<~EOF_YAML
      all:
          addresses:
            city: #{m.addresses.first.city}

          player_contacts:
            data: fake

    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be false

    confy = <<~EOF_YAML
      all:
          addresses:
            city: #{m.addresses.first.city}

          player_contacts:
            data: #{m.player_contacts.first.data}

    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be true

    confy = <<~EOF_YAML
      not_all:
          addresses:
            city: #{m.addresses.first.city}

          player_contacts:
            data: fake

    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be true

    confy = <<~EOF_YAML
      not_all:
          addresses:
            city: #{m.addresses.first.city}

          player_contacts:
            data: #{m.player_contacts.first.data}

    EOF_YAML

    conf = setup_config(confy)

    @al.reset_model_references

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be false
  end

  it 'handles deep references' do
    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 0,
                             rec_type: 'home',
                             source: 'nflpa'

    a2 = m.addresses.create! city: 'Portland',
                             state: 'OR',
                             zip: rand(99_999).to_s.rjust(5, '0').to_s,
                             rank: 10,
                             rec_type: 'home',
                             source: 'nflpa'

    @al.extra_log_type_config.references = {
      address: {
        address: {
          from: 'master',
          add: 'one_to_master'
        }
      },
      player_contact: {
        player_contact: {
          from: 'master',
          add: 'many'
        }
      }
    }

    ModelReference.create_with @al, a1, force_create: true
    ModelReference.create_with @al, a2, force_create: true

    expect(@al.model_references.length).to eq 2

    @alnor = create_item

    @alnor.master_id = @al.master_id
    @alnor.force_save!
    @alnor.save!

    @alnor.extra_log_type_config.references = {
      address: {
        address: {
          from: 'master',
          add: 'one_to_master'
        }
      },
      player_contact: {
        player_contact: {
          from: 'master',
          add: 'many'
        }
      },
      activity_log__player_contact_phone: {
        activity_log__player_contact_phone: {
          from: 'this',
          add: 'many'
        }
      }
    }

    # Create a reference to @al
    ModelReference.create_with @alnor, @al

    confy = <<~EOF_YAML
      all:
        activity_log__player_contact_phones:
          id: #{@alnor.id}


        any:
          all:
            addresses:
              city: 'portland'
              zip: x
              id:
                this_references: id


          all2:
            addresses:
              city: 'portland'
              zip: #{a2.zip}
              id:
                this_references: id

      not_all:
        activity_log__player_contact_phones:
          extra_log_type: xxx
          id:
            this_references: id
    EOF_YAML

    conf = setup_config(confy)

    # We have two references
    expect(@alnor.model_references.count).to eq 3 # two addresses and one activity log

    zcount = @alnor.model_references.select do |mr|
      mr.to_record.zip&.in?([a2.zip, 'x']) if mr.to_record.respond_to? :zip
    end.length
    expect(zcount).to be > 0

    zcount = @alnor.model_references.select do |mr|
      mr.to_record.extra_log_type == 'xxx' if mr.to_record.respond_to? :extra_log_type
    end.length
    expect(zcount).to eq 0

    # Since neither match extra_log_type xxx, not_all results in true
    res = ConditionalActions.new conf, @alnor
    expect(res.calc_action_if).to be true

    # Check it also finds a matching item with 'primary', causing the result to fail
    confy = <<~EOF_YAML
      all:
        activity_log__player_contact_phones:
          id: #{@alnor.id}


        any:
          all:
            addresses:
              city: 'portland'
              zip: x
              id:
                this_references: id


          all2:
            addresses:
              city: 'portland'
              zip: #{a2.zip}
              id:
                this_references: id

      not_all:
        activity_log__player_contact_phones:
          extra_log_type: #{@al.extra_log_type}
          id:
            this_references: id
    EOF_YAML

    conf = setup_config(confy)

    @alnor.reset_model_references

    # Since one of the references matches extra_log_type primary, not_all results in false
    res = ConditionalActions.new conf, @alnor
    expect(res.calc_action_if).to be false

    # Set the references to be disabled
    # This only affects the conditions handled by this_reference: id
    # since the initial condition is handled directly by an INNER JOIN query
    # not through the model references
    @alnor.extra_log_type_config.editable_if = { always: true }
    r = @alnor.model_references.last
    expect(r.can_disable).to be_truthy
    r.update!(disabled: true, current_user: @user) unless r.disabled?
    @alnor.reset_model_references

    res = ConditionalActions.new conf, @alnor
    res_if = res.calc_action_if

    expect(res_if).to be true
  end

  it 'checks IS (NOT) NULL conditions' do
    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          created_at: {
            condition: 'IS NULL'
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          created_at: {
            condition: 'IS NOT NULL'
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: {
            condition: 'IS NULL'
          }
        }
      }
    }
    expect(@al.select_who).not_to be nil
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    @al.update(current_user: @user, select_who: nil)
    @al = @al.class.find(@al.id)

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: {
            condition: 'IS NOT NULL'
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false
  end

  it 'checks non-equality conditions' do
    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          created_at: {
            condition: '<',
            value: (@al.created_at + 1.second).to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,

          created_at: {
            condition: '>',
            value: (@al.created_at + 1.second).to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    @al.force_save!
    @al.updated_at = DateTime.now
    @al.save!

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,

          updated_at: {
            condition: '<=',
            value: 'now()'
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,

          updated_at: {
            condition: '<',
            value: '+1 day'
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,

          updated_at: {
            condition: '>',
            value: '-1 day'
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: {
            condition: '<>',
            value: @al.select_who
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: {
            condition: '<',
            value: "a-#{@al.select_who}"
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Special check to ensure that extra conditions like these work when there are no standard equality conditions
    # included (this was previously a bug where the extra conditions were ignored)
    conf = {
      any: {
        activity_log__player_contact_phones: {
          id: @al.id
        }
      },
      all: {
        activity_log__player_contact_phones: {
          created_at: {
            condition: '<',
            value: (@al.created_at + 1.second).to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      any: {
        activity_log__player_contact_phones: {
          id: @al.id
        }
      },
      all: {
        activity_log__player_contact_phones: {
          created_at: {
            condition: '>',
            value: (@al.created_at + 1.second).to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Special conditions are not supported on any or not_any
    # Ensure we get an obvious exception
    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id
        }
      },
      any: {
        activity_log__player_contact_phones: {
          created_at: {
            condition: '<',
            value: (@al.created_at + 1.second).to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect do
      res.calc_action_if
    end.to raise_error(FphsException)

    # Right to Left conditions
    expect(@al.select_who.length).to be > 0

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: {
            condition: '= LENGTH',
            value: @al.select_who.length.to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    # Right to Left conditions
    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: {
            condition: '= LENGTH',
            value: (@al.select_who.length + 1).to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Right to Left conditions in "this" - a special case that requires extra calculation
    conf = {
      all: {
        this: {
          select_who: {
            condition: '= LENGTH',
            value: (@al.select_who.length + 1).to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    # Right to Left conditions in "this" - a special case that requires extra calculation
    conf = {
      all: {
        this: {
          select_who: {
            condition: '= LENGTH',
            value: @al.select_who.length.to_s
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true
  end

  describe 'returning values' do
    it 'returns the last value from a condition as this_val attribute' do
      conf = {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: 'return_value'
        }
      }

      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq @al.select_who

      conf = {
        activity_log__player_contact_phones: {
          id: @al.id + 100,
          select_who: 'return_value'
        }
      }

      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to be nil

      conf = {
        this: {
          select_who: 'return_value'
        }
      }

      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq @al.select_who
    end

    it 'returns the return_value attribute from whichever subcondition is matched first' do
      # Alternatively return one value or another
      conf = {

        any: {
          any_1: {
            activity_log__player_contact_phones: {
              id: @al2.id + 100,
              select_who: 'return_value'
            }
          },
          any_2: {
            activity_log__player_contact_phones: {
              id: @al.id,
              select_who: 'return_value'
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq @al.select_who

      conf = {
        any: {
          any_1: {
            activity_log__player_contact_phones: {
              id: @al2.id,
              select_who: ['return_value']
            }
          },
          any_2: {
            activity_log__player_contact_phones: {
              id: @al.id + 100,
              select_who: 'return_value'
            }
          }
        }
      }

      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq @al2.select_who
    end

    it 'returns an attribute that matches any item in a list, when return_value is the last entry in the list' do
      conf = {
        any: {
          all_1: {
            activity_log__player_contact_phones: {
              id: [@al2.id,
                   'return_value']
            }
          },
          all_2: {
            activity_log__player_contact_phones: {
              id: [@al.id + 100,
                   'return_value']

            }
          }
        }
      }

      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq @al2.id
    end

    it 'returns the all values as a list from a condition as this_val attribute' do
      @al1 = create_item
      @al1.update! select_who: 'someone new', current_user: @user, master_id: @al.master_id

      expect(@al.master_id).to eq @al0.master_id
      expect(@al.master_id).to eq @al1.master_id

      conf = {
        activity_log__player_contact_phones: {
          select_who: 'return_value_list',
          id: [@al.id, @al0.id, @al1.id]
        }
      }

      ca = ConditionalActions.new conf, @al

      res = ca.get_this_val
      expect(res).to eq [@al1.select_who, @al.select_who, @al0.select_who]
    end

    it 'returns a record using return_result' do
      @al1 = create_item
      @al1.update! select_who: 'someone new', current_user: @user, master_id: @al.master_id

      expect(@al.master_id).to eq @al0.master_id
      expect(@al.master_id).to eq @al1.master_id

      conf = {
        activity_log__player_contact_phones: {
          select_who: 'return_value_list',
          id: @al0.id,
          return: 'return_result'
        }
      }

      ca = ConditionalActions.new conf, @al

      res = ca.get_this_val
      expect(res).to eq @al0
    end
  end

  describe 'returns a constant value if the condition is matched' do
    it 'is matched in a simple reference' do
      conf = {
        activity_log__player_contact_phones: {
          id: @al.id,
          return_constant: 'yes'
        }
      }

      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq 'yes'
    end

    it 'is matched in this current record' do
      conf = {
        activity_log__player_contact_phones: {
          id: @al.id + 1,
          return_constant: 'yes'
        }
      }
      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to be nil

      conf = {
        all: {
          this: {
            select_who: @al.select_who,
            user_id: @al.user_id,
            return_constant: 'random constant'
          }
        }
      }
      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq 'random constant'
    end

    it 'returns a constant from a second sub-condition' do
      conf = {
        all: {
          all_2: {
            this: {

              select_who: @al.select_who,
              user_id: @al.user_id
            }
          },
          all_3: {
            this: {
              return_constant: 'random constant2'
            }
          }
        }
      }
      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq 'random constant2'

      conf = {
        all: {
          all_2: {
            this: {

              select_who: @al.select_who,
              user_id: -1
            }
          },
          all_3: {
            this: {
              return_constant: 'random constant2'
            }
          }
        }
      }
      ca = ConditionalActions.new conf, @al
      res = ca.get_this_val
      expect(res).to eq nil
    end
  end

  describe 'getting referring record attributes and checking existence' do
    before :each do
      create_user
      setup_access :activity_log__player_contact_phones
      setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
      setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type

      # create_master

      @alref = create_item
      @alref.current_user = @user

      @alref1 = create_item
      @alref1.update! select_who: 'someone new', current_user: @user, master_id: @alref.master_id

      @alref2 = create_item
      @alref2.update! select_who: 'someone else new', current_user: @user, master_id: @alref.master_id

      @alref1.reload
      @alref2.reload
      @alref1.current_user = @user
      @alref2.current_user = @user

      expect(@alref.master_id).to eq @alref2.master_id
      expect(@alref.master_id).to eq @alref1.master_id

      @alref.extra_log_type_config.references = {
        activity_log__player_contact_phone: {
          from: 'this',
          add: 'many'
        }
      }

      @alref.extra_log_type_config.clean_references_def
      @alref.extra_log_type_config.editable_if = { always: true }

      ModelReference.create_with @alref, @alref1, force_create: true
      ModelReference.create_with @alref, @alref2, force_create: true

      expect(@alref.model_references.length).to eq 2
    end

    it 'returns a referring record attribute' do
      conf = {
        referring_record: {
          id: 'return_value'
        }
      }

      ca = ConditionalActions.new conf, @alref2

      res = ca.get_this_val
      expect(res).to eq @alref.id
    end

    it 'checks a referring record exists' do
      conf = {
        all: {
          referring_record: {
            exists: true
          }
        }
      }

      res = ConditionalActions.new conf, @alref2
      expect(res.calc_action_if).to be true

      res = ConditionalActions.new conf, @alref
      expect(res.calc_action_if).to be false
    end

    it 'returns a whole record as a result of finding a reference' do
      conf = {
        activity_log__player_contact_phones: {
          id: {
            referring_record: 'id'
          },
          update: 'return_result'
        }
      }

      ca = ConditionalActions.new conf, @alref2

      res = ca.get_this_val
      expect(res).to eq @alref
    end

    it 'returns the first record referring to this one' do
      conf = {
        referring_record: {
          update: 'return_result'
        }
      }

      ca = ConditionalActions.new conf, @alref2

      res = ca.get_this_val
      expect(res).to eq @alref
    end

    it 'returns the top record from the tree of referring records' do
      # Top referring record
      conf = {
        top_referring_record: {
          update: 'return_result'
        }
      }

      ca = ConditionalActions.new conf, @alref2

      res = ca.get_this_val
      expect(res).to eq @alref
    end
  end

  describe 'finding parent references' do
    before :example do
      @new_al0 = create_item
      @new_al0.extra_log_type = 'blank_log'
      expect(@new_al0.class.definition.option_type_config_for('blank_log')).not_to be nil
      @new_al0.force_save!
      @new_al0.save!

      @new_al = create_item
      @new_al.master_id = @new_al0.master_id
      @new_al.extra_log_type = 'primary'
      @new_al.force_save!
      @new_al.save!

      new_al2 = create_item
      new_al2.master_id = @new_al0.master_id
      new_al2.extra_log_type = 'ignore_missing_elt'
      new_al2.force_save!
      new_al2.save!

      @new_al.extra_log_type_config.references = {
        activity_log__player_contact_phone: {
          from: 'this',
          add: 'many'
        }
      }
      @new_al.extra_log_type_config.clean_references_def

      @new_al0.extra_log_type_config.references = {
        activity_log__player_contact_phone: {
          from: 'this',
          add: 'many'
        }
      }
      @new_al0.extra_log_type_config.clean_references_def

      m = @new_al0.master
      m.current_user = @user
      data = "(516)123-7612-#{DateTime.now.to_f}"
      @pc = m.player_contacts.first
      @pc.update! data: data, rec_type: 'phone', rank: 10, source: 'nflpa'

      expect(@new_al.extra_log_type).not_to be nil
      expect(m.activity_log__player_contact_phones.where(extra_log_type: 'primary').count).to be > 0

      # Make al refer to al0 (al is the parent of al0)
      ModelReference.create_with @new_al, @new_al0, force_create: true
      expect(@new_al0.referring_record).to eq @new_al
      expect(@new_al0.extra_log_type).to eq :blank_log
      ModelReference.create_with @new_al, new_al2, force_create: true
      expect(new_al2.referring_record).to eq @new_al
      expect(new_al2.extra_log_type).to eq :ignore_missing_elt

      mls = @new_al.model_references(force_reload: true).length
      expect(mls).to eq 2
    end

    it 'finds a parent references matching the id of a specific activity log' do
      confy = <<~EOF_YAML
        all:
          activity_log__player_contact_phones:
            extra_log_type: ignore_missing_elt
            id:
              parent_references: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true
    end

    it 'will not return parent references where the attribute does not match' do
      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: primary
            id:
              parent_references: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false
    end

    it 'checks if this item is one of those referenced by its parent' do
      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: blank_log
            id:
              parent_references: id

      EOF_YAML

      conf = setup_config(confy)

      expect(@new_al0.referring_record).to eq @new_al
      mrs = @new_al.model_references.map(&:to_record_id)
      expect(mrs).to include @new_al0.id
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true
    end

    it 'checks for a parent reference record with a specific type' do
      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: blank_log
            id:
              parent_references:
                activity_log__player_contact_phones: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true
    end

    it 'returns nothing if the parent reference does not match the specified type' do
      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: primary
            id:
              parent_references:
                activity_log__player_contact_phones: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false

      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: primary
            id:
              parent_references:
                player_contact: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false
    end

    it 'provides parent_or_this_references to make reusable references' do
      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: blank_log
            id:
              parent_or_this_references:
                activity_log__player_contact_phones: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: primary
            id:
              parent_or_this_references:
                activity_log__player_contact_phones: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false
    end

    it 'provides parent_or_this, which can fall back to the current instance' do
      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: blank_log
            id:
              parent_or_this_references:
                activity_log__player_contact_phones: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al
      expect(res.calc_action_if).to be true

      confy = <<~EOF_YAML
        all:

          activity_log__player_contact_phones:
            extra_log_type: primary
            id:
              parent_or_this_references:
                activity_log__player_contact_phones: id

      EOF_YAML

      conf = setup_config(confy)

      res = ConditionalActions.new conf, @new_al
      expect(res.calc_action_if).to be false
    end
  end

  it 'checks if all attributes had a certain value before changes were saved' do
    al_changed = create_item
    al_changed.master_id = @al.master_id
    al_changed.select_who = 'testselect'
    al_changed.force_save!
    al_changed.save!

    al_changed.master_id = @al.master_id
    al_changed.select_who += '-alt'
    # al_changed.force_save!
    al_changed.save!

    expect(al_changed.attribute_before_last_save('select_who')).to eq 'testselect'

    conf = {
      all: {
        this: {
          select_who: 'testselect-alt',
          user_id: @al.user_id,
          previous_value_of_select_who: 'testselect'
        }
      }
    }

    res = ConditionalActions.new conf, al_changed
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        this: {
          select_who: 'testselect-alt',
          user_id: @al.user_id,
          previous_value_of_select_who: 'testselect-alt'
        }
      }
    }

    res = ConditionalActions.new conf, al_changed
    expect(res.calc_action_if).to be false

    al_changed.master_id = @al.master_id
    al_changed.select_who = nil
    # al_changed.force_save!
    al_changed.save!

    conf = {
      all: {
        this: {
          select_who: nil,
          user_id: @al.user_id,
          previous_value_of_select_who: 'testselect-alt'
        }
      }
    }

    res = ConditionalActions.new conf, al_changed
    expect(res.calc_action_if).to be true

    al_changed.master_id = @al.master_id
    al_changed.select_who = 'newval'
    # al_changed.force_save!
    al_changed.save!

    conf = {
      all: {
        this: {
          select_who: 'newval',
          user_id: @al.user_id,
          previous_value_of_select_who: nil
        }
      }
    }

    res = ConditionalActions.new conf, al_changed
    expect(res.calc_action_if).to be true

    al_changed.master_id = @al.master_id
    al_changed.select_who = 'newval2'
    # al_changed.force_save!
    al_changed.save!

    conf = {
      all: {
        this: {
          select_who: 'newval2',
          user_id: @al.user_id,
          previous_value_of_select_who: 'return_value'
        }
      }
    }

    res = ConditionalActions.new conf, al_changed
    expect(res.get_this_val).to eq 'newval'
  end

  context 'calculates special cases' do
    before :each do
      @junk_master = Master.create! current_user: @user
      @new_al0 = create_item

      @new_al = create_item

      @new_al.master_id = @new_al0.master_id
      @new_al.extra_log_type = 'primary'
      @new_al.force_save!
      @new_al.save!

      m = @new_al0.master
      m.current_user = @user
      data = "(516)123-7612-#{DateTime.now.to_f}"
      @pc = m.player_contacts.first
      @pc.update! data: data, rec_type: 'phone', rank: 10, source: 'nflpa'
      @pc.master.player_contacts.where.not(id: @pc.id).update_all(master_id: @junk_master)

      expect(@new_al.extra_log_type).not_to be nil
      expect(m.activity_log__player_contact_phones.where(extra_log_type: 'primary').count).to be > 0
    end

    it 'Checks script ineligibility test' do
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              extra_log_type: ineligible
          any_ineligible:
            all_basic_questions:
              activity_log__player_contact_phones:
                extra_log_type: primary
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      expect(@new_al.master_id).to eq @new_al0.master_id

      # all:
      #   not_any:
      #     activity_log__player_contact_phones:
      #       extra_log_type: ineligible
      elts = @new_al0.master.activity_log__player_contact_phones.where(extra_log_type: 'ineligible')
      expect(elts.count).to eq 0

      # all:
      #   any_ineligible:
      #     all_basic_questions:
      #       activity_log__player_contact_phones:
      #         extra_log_type: primary
      #       [...]
      elts = @new_al0.master.activity_log__player_contact_phones.where(extra_log_type: 'primary')
      expect(elts.count).to be > 0

      # all:
      #   any_ineligible:
      #     all_basic_questions:
      #       [...]
      #       not_all:
      #         all_phq8_eligible:
      #           player_contacts:
      #             rank:
      #               condition: '<'
      #               value: 10

      # Ensure there is only one player contact
      @new_al0.master.player_contacts.where.not(id: @pc.id).update_all(master_id: @junk_master.id)

      @pc.update! rank: 10
      pcs = @new_al0.master.player_contacts.where('rank < 10')
      expect(pcs.count).to eq 0

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      ####
      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false
    end

    it 'Checks script ineligibility - alternative nesting' do
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              extra_log_type: ineligible
          any_ineligible:
            all_basic_questions:
              all:
                activity_log__player_contact_phones:
                  extra_log_type: #{@new_al.extra_log_type}
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10

      # An activity log does not exist with elt ineligble
      expect(@pc.master.activity_log__player_contact_phones.where(extra_log_type: 'ineligible').count).to eq 0
      # And an activity log exists with elt primary
      expect(@pc.master.activity_log__player_contact_phones.where(extra_log_type: 'primary').count).to be > 0
      # and player contact does not have a condition less than 10
      expect(@pc.master.player_contacts.where('rank < 10').count).to eq 0

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false
    end

    it 'It checks script eligibility' do
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              extra_log_type: eligible
          all_done:
            activity_log__player_contact_phones:
              extra_log_type: #{@new_al.extra_log_type}
          all_phq8_eligible:
            player_contacts:
              rank:
                condition: '<'
                value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false

      @pc.update! rank: 5

      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true
    end

    it 'Checks "any" also works' do
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              extra_log_type: ineligible
          any_ineligible:
            any_basic_questions:
              activity_log__player_contact_phones:
                # the first on should not match, but the id should
                extra_log_type: will not match
                id: #{@new_al.id}
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      ###
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              # This will not match, meaning not_any will pass
              extra_log_type: ineligible
          any_ineligible:
            any_basic_questions:
              activity_log__player_contact_phones:
                # neither should match
                extra_log_type: will not match
                id: -1
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false
    end

    it 'checks "not_all" also works' do
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              extra_log_type: ineligible
          any_ineligible:
            not_all_basic_questions:
              activity_log__player_contact_phones:
                # the first on should not match, but the id should
                extra_log_type: will not match
                id: #{@new_al.id}
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true

      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              # This will not match, meaning not_any will pass
              extra_log_type: ineligible
          any_ineligible:
            not_all_basic_questions:
              activity_log__player_contact_phones:
                # both should match
                extra_log_type: primary
                id: #{@new_al.id}
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true
    end

    it 'Checks a combined not_all' do
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              # This will not match, meaning not_any will pass
              extra_log_type: ineligible
          any_ineligible:
            not_all_basic_questions:
              activity_log__player_contact_phones:
                # both should match
                extra_log_type: primary
                id: #{@new_al.id}
              player_contacts:
                rank:
                  condition: '>='
                  value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true
    end

    it 'hecks "not_any" also works' do
      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              extra_log_type: ineligible
          any_ineligible:
            not_any_basic_questions:
              activity_log__player_contact_phones:
                # the first on should not match, but the id should
                extra_log_type: will not match
                id: #{@new_al.id}
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false

      confy = <<~EOF_YAML
        all:
          not_any:
            activity_log__player_contact_phones:
              # This will not match, meaning not_any will pass
              extra_log_type: ineligible
          any_ineligible:
            not_any_basic_questions:
              activity_log__player_contact_phones:
                # neither should match
                extra_log_type: will not match
                id: -1
              not_all:
                all_phq8_eligible:
                  player_contacts:
                    rank:
                      condition: '<'
                      value: 10
      EOF_YAML

      conf = setup_config(confy)

      @pc.update! rank: 10
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be false

      @pc.update! rank: 5
      res = ConditionalActions.new conf, @new_al0
      expect(res.calc_action_if).to be true
    end
  end

  describe 'finding users system-wide (in the users table)' do
    before :each do
      prev_user = @user
      @alt_user, = create_user
      @disabled_user, = create_user
      @disabled_user.update!(disabled: true, current_admin: @admin)
      @alt_user2, = create_user
      @user = prev_user
    end

    it 'finds the user' do
      expect(User.find_by(email: @alt_user.email)).to be_a User

      conf = {
        all: {
          users: {
            email: @alt_user.email
          }
        }
      }
      res = ConditionalActions.new conf, @al
      expect(res.calc_action_if).to be true
    end

    it "doesn't find the user if it is disabled" do
      expect(User.where(email: @disabled_user.email, disabled: [nil, false]).count).to eq 0
      conf = {
        all: {
          users: {
            email: @disabled_user.email,
            disabled: [nil, false]
          }
        }
      }
      ca = ConditionalActions.new conf, @al
      res = ca.calc_action_if
      expect(res).to be false
    end

    it 'ensures an active user matches a record attribute' do
      conf = {
        all: {
          users: {
            id: {
              player_contacts: {
                user_id: 'return_value'
              }
            }
          }
        }
      }
      res = ConditionalActions.new conf, @al
      expect(res.calc_action_if).to be true
    end

    it 'gets an attribute from an active user' do
      conf = {

        users: {
          email: @alt_user2.email,
          disabled: [nil, false],
          id: 'return_value'
        }

      }
      ca = ConditionalActions.new conf, @al
      expect(ca.get_this_val).to eq @alt_user2.id
    end
    it 'fails to gets an attribute from a disabled user' do
      conf = {
        all: {
          users: {
            email: @disabled_user.email,
            disabled: [nil, false],
            id: 'return_value'
          }
        }
      }
      ca = ConditionalActions.new conf, @al
      expect(ca.get_this_val).to be nil
    end
  end
end
