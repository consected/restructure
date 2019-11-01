require 'rails_helper'

RSpec.describe "Calculate conditional actions", type: :model do

  include ModelSupport
  include ActivityLogSupport

  before :all do

    u1, _ = create_user
    @u1 = u1
    create_user
    create_master
    let_user_create_player_contacts

    setup_access :activity_log__player_contact_phones
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


  it "always returns false for never and true for always" do

    conf = {never: true}
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

    conf = {always: true}
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

  end

  it "checks if all attributes have a certain value" do

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

  it "checks if any attributes have a certain value" do

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


  it "checks if none of the attributes have a certain value" do

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


  it "checks if not all the attributes have a certain value" do

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


  it "checks if all attributes in this and another table in the master have a certain value" do

    m = @al.master
    m.current_user = @user
    pc = m.player_contacts.create! data: '(516)123-7612', rec_type: 'phone', rank: 10, source: 'nflpa'

    conf = {
      all: {
        this: {
            select_who: @al.select_who,
            user_id: @al.user_id
        },
        player_contacts: {
          data: pc.data
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
          data: pc.data
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

  it "checks if all attributes match multiple condition types" do

    m = @al.master
    m.current_user = @user
    pc = m.player_contacts.create! data: '(516)123-7612', rec_type: 'phone', rank: 10, source: 'nflpa'

    conf = {
      all: {
        this: {
            select_who: @al.select_who,
            user_id: @al.user_id
        },
        player_contacts: {
          data: pc.data
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
          data: pc.data
        }
      },
      not_any: {
        player_contacts: {
          data: pc.data
        }
      }
    }
    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

  end

  it "checks for lists of possible items in the the same table with different sets of attributes" do

    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: "Portland",
      state: "OR",
      zip: "#{rand(99999).to_s.rjust(5, "0")}",
      rank: 0,
      rec_type: 'home',
      source: 'nflpa'

    m.addresses.create! city: "Portland",
      state: "OR",
      zip: "#{rand(99999).to_s.rjust(5, "0")}",
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

  it "checks if nested conditions work" do

    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: "Portland",
      state: "OR",
      zip: "#{rand(99999).to_s.rjust(5, "0")}",
      rank: 0,
      rec_type: 'home',
      source: 'nflpa'

    a2 = m.addresses.create! city: "Portland",
      state: "OR",
      zip: "#{rand(99999).to_s.rjust(5, "0")}",
      rank: 10,
      rec_type: 'home',
      source: 'nflpa'

    pc = m.player_contacts.create! data: '(516)123-7612', rec_type: 'phone', rank: 10, source: 'nflpa'

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
            data: pc.data
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
            data: pc.data + '-bad'
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
                data: pc.data
              }
            },
            {
              player_contacts: {
                id: pc.id
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
                id: pc.id
            }

          },

          # A player contact record exists in the master
          all_pcs_with_data: {
            player_contacts: {
              id: pc.id,
              data: pc.data
            }
          }
        }
      }

    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

  end

  it "checks if a certain the current user has a specific role" do

    conf = {
      all: {
        user: {
          role_name: 'test-role'
        }
      }
    }

    res = ConditionalActions.new conf, @al

    expect(res.calc_action_if).to be false

    Admin::UserRole.create! current_admin: @admin, role_name: 'test-role', app_type: @user.app_type, user: @user

    conf = {
      all: {
        user: {
          role_name: 'test-role'
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true


    conf = {
      all: {
        user: {
          role_name: ['test-role', 'x']
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true

    conf = {
      all: {
        user: {
          role_name: ['y', 'x']
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

  end

  it "handles repeated, nested items" do


    m = @al.master
    m.current_user = @user

    a1 = m.addresses.create! city: "Portland",
      state: "OR",
      zip: "#{rand(99999).to_s.rjust(5, "0")}",
      rank: 0,
      rec_type: 'home',
      source: 'nflpa'

    a2 = m.addresses.create! city: "Portland",
      state: "OR",
      zip: "#{rand(99999).to_s.rjust(5, "0")}",
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

    confy= "
    all:
      addresses:
        city: 'portland'
        zip: '#{a1.zip}'
        id:
          this_references: id
    "
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true



    confy = "
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
"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be true




    confy = "
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
"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al

    expect(res.calc_action_if).to be true



    # # Try matching any across multiple relations
    m.player_contacts.create! rec_type: :phone, data: '(123)456-7891', rank: 5
    m.player_contacts.create! rec_type: :phone, data: '(123)456-7892', rank: 10
    # ModelReference.create_with @al, pc1
    # ModelReference.create_with @al, pc2
    #
    # expect(@al.model_references.length).to eq 4

    # Check that we correctly join in the queries so that any / not_any work as expected

    confy = "
        any:
            addresses:
              city: #{m.addresses.first.city}

            player_contacts:
              data: fake


"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be true


    confy = "
        not_any:
            addresses:
              city: #{m.addresses.first.city}

            player_contacts:
              data: fake


"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be false


    confy = "
        all:
            addresses:
              city: #{m.addresses.first.city}

            player_contacts:
              data: fake


"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be false


    confy = "
        all:
            addresses:
              city: #{m.addresses.first.city}

            player_contacts:
              data: #{m.player_contacts.first.data}


"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be true


    confy = "
        not_all:
            addresses:
              city: #{m.addresses.first.city}

            player_contacts:
              data: fake


"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be true


    confy = "
        not_all:
            addresses:
              city: #{m.addresses.first.city}

            player_contacts:
              data: #{m.player_contacts.first.data}


"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    res = ConditionalActions.new conf, @al

    a = res.calc_action_if
    expect(a).to be false



    # Expect this one to fail, as the references do not exist when using @alnor as the object in ConditionalActions
    @alnor = create_item

    @alnor.master_id = @al.master_id
    @alnor.force_save!
    @alnor.save!

    confy = "
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
"
    conf = YAML.load(confy)
    conf = conf.deep_symbolize_keys

    # expect(@alnor.model_references.count).to eq 2 # two dynamic models only

    res = ConditionalActions.new conf, @alnor
    # expect(res.calc_action_if).to be true

    @alnor.extra_log_type_config.editable_if = {always: true}

    @alnor.model_references.each do |r|
      r.update!(disabled: true, current_user: @user) unless r.disabled?
    end


    res_if = res.calc_action_if

    expect(res_if).to be false

  end

  it "checks non-equality conditions" do

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          created_at: {
            condition: "<",
            value: "#{@al.created_at + 1.second}"
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
            condition: ">",
            value: "#{@al.created_at + 1.second}"
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
            condition: "<>",
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
            condition: "<",
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
            condition: "<",
            value: "#{@al.created_at + 1.second}"
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
            condition: ">",
            value: "#{@al.created_at + 1.second}"
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
            condition: "<",
            value: "#{@al.created_at + 1.second}"
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect {
      res.calc_action_if
    }.to raise_error(FphsException)


    # Right to Left conditions
    expect(@al.select_who.length).to be > 0

    conf = {
      all: {
        activity_log__player_contact_phones: {
          id: @al.id,
          select_who: {
            condition: "= LENGTH",
            value: "#{@al.select_who.length}"
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
            condition: "= LENGTH",
            value: "#{@al.select_who.length + 1}"
          }
        }
      }
    }

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false

  end

  it "returns the last value from a condition as this_val attribute" do
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
        id: @al.id+100,
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

  it "returns the all values as a list from a condition as this_val attribute" do

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


  it "returns a record using return_result" do

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

  it "returns a constant value if the condition is matched" do
    conf = {
      activity_log__player_contact_phones: {
        id: @al.id,
        return_constant: 'yes'
      }
    }

    ca = ConditionalActions.new conf, @al
    res = ca.get_this_val
    expect(res).to eq 'yes'

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

  end

  it "returns a referring record attribute" do

    create_user
    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type


    # create_master

    @al = create_item
    @al.current_user = @user


    @al1 = create_item
    @al1.update! select_who: 'someone new', current_user: @user, master_id: @al.master_id

    @al2 = create_item
    @al2.update! select_who: 'someone else new', current_user: @user, master_id: @al.master_id

    @al1.reload
    @al2.reload
    @al1.current_user = @user
    @al2.current_user = @user

    expect(@al.master_id).to eq @al2.master_id
    expect(@al.master_id).to eq @al1.master_id

    @al.extra_log_type_config.references = {
      activity_log__player_contact_phone: {
        from: 'this',
        add: 'many'
      }
    }

    @al.extra_log_type_config.clean_references_def
    @al.extra_log_type_config.editable_if = {always: true}

    ModelReference.create_with @al, @al1, force_create: true
    ModelReference.create_with @al, @al2, force_create: true

    expect(@al.model_references.length).to eq 2

    conf = {
      referring_record: {
        id: 'return_value'
      }
    }

    ca = ConditionalActions.new conf, @al2

    res = ca.get_this_val
    expect(res).to eq @al.id

    conf = {
      all: {
        referring_record: {
          exists: true
        }
      }
    }

    res = ConditionalActions.new conf, @al2
    expect(res.calc_action_if).to be true

    res = ConditionalActions.new conf, @al
    expect(res.calc_action_if).to be false



    conf = {
      activity_log__player_contact_phones: {
        id: {
          referring_record: 'id'
        },
        update: 'return_result'
      }
    }

    ca = ConditionalActions.new conf, @al2

    res = ca.get_this_val
    expect(res).to eq @al



    conf = {
      referring_record: {
        update: 'return_result'
      }
    }

    ca = ConditionalActions.new conf, @al2

    res = ca.get_this_val
    expect(res).to eq @al

  end

end
