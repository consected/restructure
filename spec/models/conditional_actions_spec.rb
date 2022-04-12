# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ConditionalActions, type: :model do
  include ModelSupport

  describe 'calc_save_option_if for save_action and save_trigger options' do
    context 'provides control for save triggers with multiple actions' do
      before :each do
        @config = {
          on_create: {
            do_trigger: [
              {
                type: 'trigger1',
                if: {
                  all: {
                    this: {
                      user_id: -1
                    }
                  }
                }
              },
              {
                type: 'trigger2',
                if: {
                  all: {
                    this: {
                      user_id: -1
                    }
                  }
                }
              }
            ]
          },
          on_update: {
            do_trigger: [
              {
                type: 'trigger3',
                if: {
                  all: {
                    this: {
                      user_id: -1
                    }
                  }
                }
              },
              {
                type: 'trigger4',
                if: {
                  all: {
                    this: {
                      user_id: 10
                    }
                  }
                }
              }
            ]
          }
        }
      end

      it 'passes responsibility for conditional if checks for each action back to the caller' do
        test_object = double(user_id: -1)
        ca = ConditionalActions.new @config, test_object
        res = ca.calc_save_option_if

        expect(res).to eq(
          on_create: {
            do_trigger: true
          },
          on_update: {
            do_trigger: true
          }
        )

        test_object = double(user_id: -10)
        ca = ConditionalActions.new @config, test_object
        res = ca.calc_save_option_if

        expect(res).to eq(
          on_create: {
            do_trigger: true
          },
          on_update: {
            do_trigger: true
          }
        )
      end
    end

    context 'provides control for save triggers with single actions as a hash' do
      before :each do
        @config = {
          on_create: {
            do_trigger: {
              type: 'trigger1',
              if: {
                all: {
                  this: {
                    user_id: -1
                  }
                }
              }
            }
          },
          on_update: {
            do_trigger: {
              type: 'trigger2',
              if: {
                all: {
                  this: {
                    user_id: -1
                  }
                }
              }
            }
          }
        }
      end

      it 'passes responsibility for conditional if checks for each action back to the caller' do
        test_object = double(user_id: -1)
        ca = ConditionalActions.new @config, test_object
        res = ca.calc_save_option_if

        expect(res).to eq(
          on_create: {
            do_trigger: true
          },
          on_update: {
            do_trigger: true
          }
        )

        test_object = double(user_id: -10)
        ca = ConditionalActions.new @config, test_object
        res = ca.calc_save_option_if

        expect(res).to eq(
          on_create: {
            do_trigger: true
          },
          on_update: {
            do_trigger: true
          }
        )
      end
    end

    context 'provides control for save actions with single actions and returns their values if their conditions are met' do
      before :each do
        create_admin
        @user1 = User.create!(email: 'conditional-actions1@test', first_name: 'fn', last_name: 'ln', disabled: false, current_admin: @admin)
        @user2 = User.create!(email: 'conditional-actions2@test', first_name: 'fn', last_name: 'ln', disabled: false, current_admin: @admin)

        @test_object = double(id: 1)

        @config = {
          on_create: {
            do_trigger: {
              value: 'trigger1',
              if: {
                all: {
                  users: {
                    email: @user1.email,
                    disabled: false
                  }
                }
              }
            },
            do_trigger2: {
              value: 'trigger2',
              if: {
                all: {
                  users: {
                    email: @user1.email,
                    disabled: false
                  }
                }
              }
            }

          },
          on_update: {
            do_trigger: {
              value: 'trigger4',
              if: {
                all: {
                  users: {
                    email: @user2.email,
                    disabled: false
                  }
                }
              }
            },
            do_trigger3: {
              value: 'trigger5',
              if: {
                all: {
                  users: {
                    email: @user1.email,
                    disabled: false
                  }
                }
              }
            }

          }
        }
      end

      it 'returns the value if the condition is matched' do
        expect(@user1.disabled).to be false
        expect(@user2.disabled).to be false
        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq(
          on_create: {
            do_trigger: 'trigger1',
            do_trigger2: 'trigger2'

          },
          on_update: {
            do_trigger: 'trigger4',
            do_trigger3: 'trigger5'
          }
        )
      end

      it 'returns an empty hash if nothing is matched' do
        @user1.disable!
        @user2.disable!
        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq({})
      end

      it 'returns result for a single match' do
        @user1.disable!
        expect(@user2.disabled).to be false

        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq(
          on_update: {
            do_trigger: 'trigger4'
          }
        )
      end
    end

    context 'provides control for save actions with multiple actions and calculates if conditions for them' do
      before :each do
        create_admin
        @user1 = User.create!(email: 'conditional-actions1@test', first_name: 'fn', last_name: 'ln', disabled: false, current_admin: @admin)
        @user2 = User.create!(email: 'conditional-actions2@test', first_name: 'fn', last_name: 'ln', disabled: false, current_admin: @admin)
        @user3 = User.create!(email: 'conditional-actions3@test', first_name: 'fn', last_name: 'ln', disabled: true, current_admin: @admin)

        @test_object = double(id: 1)

        @config = {
          on_create: {
            do_trigger: [
              {
                type: 'trigger1',
                if: {
                  all: {
                    users: {
                      email: @user1.email,
                      disabled: false
                    }
                  }
                }
              },
              {
                type: 'trigger2',
                if: {
                  all: {
                    users: {
                      email: @user1.email,
                      disabled: false
                    }
                  }
                }
              }
            ]
          },
          on_update: {
            do_trigger: [
              {
                type: 'trigger3',
                if: {
                  all: {
                    users: {
                      email: @user1.email,
                      disabled: false
                    }
                  }
                }
              },
              {
                type: 'trigger4',
                if: {
                  all: {
                    users: {
                      email: @user2.email,
                      disabled: false
                    }
                  }
                }
              }
            ],
            do_trigger2: [
              {
                value: 'trigger2a',
                if: {
                  all: {
                    users: {
                      email: @user3.email,
                      disabled: false
                    }
                  }
                }
              },
              {
                value: 'trigger2b',
                if: {
                  all: {
                    users: {
                      email: @user3.email,
                      disabled: false
                    }
                  }
                }
              }
            ]
          }
        }
      end

      it 'returns the true for any condition matched' do
        expect(@user1.disabled).to be false
        expect(@user2.disabled).to be false
        expect(@user3.disabled).to be true

        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq(
          on_create: {
            do_trigger: true
          },
          on_update: {
            do_trigger: true
          }
        )
      end

      it 'returns an empty hash if nothing is matched' do
        @user1.disable!
        @user2.disable!
        expect(@user3.disabled).to be true

        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq({})
      end

      it 'returns result for a single match' do
        @user1.disable!
        expect(@user2.disabled).to be false
        expect(@user3.disabled).to be true

        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq(
          on_update: {
            do_trigger: true
          }
        )
      end

      it 'returns result for each action' do
        @user1.disable!
        expect(@user2.disabled).to be false
        @user3.update!(disabled: false)

        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq(
          on_update: {
            do_trigger: true,
            do_trigger2: 'trigger2a'
          }
        )
      end
    end

    context 'provides control for save actions with multiple actions and returns their values if their conditions are met' do
      before :each do
        create_admin
        @user1 = User.create!(email: 'conditional-actions1@test', first_name: 'fn', last_name: 'ln', disabled: false, current_admin: @admin)
        @user2 = User.create!(email: 'conditional-actions2@test', first_name: 'fn', last_name: 'ln', disabled: false, current_admin: @admin)

        @test_object = double(id: 1)

        @config = {
          on_create: {
            do_trigger: [
              {
                value: 'trigger1',
                if: {
                  all: {
                    users: {
                      email: @user1.email,
                      disabled: false
                    }
                  }
                }
              },
              {
                value: 'trigger2',
                if: {
                  all: {
                    users: {
                      email: @user1.email,
                      disabled: false
                    }
                  }
                }
              }
            ]
          },
          on_update: {
            do_trigger: [
              {
                value: 'trigger3',
                if: {
                  all: {
                    users: {
                      email: @user1.email,
                      disabled: false
                    }
                  }
                }
              },
              {
                value: 'trigger4',
                if: {
                  all: {
                    users: {
                      email: @user2.email,
                      disabled: false
                    }
                  }
                }
              }
            ]
          }
        }
      end

      it 'returns the value for the first condition matched' do
        expect(@user1.disabled).to be false
        expect(@user2.disabled).to be false
        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq(
          on_create: {
            do_trigger: 'trigger1'
          },
          on_update: {
            do_trigger: 'trigger3'
          }
        )
      end

      it 'returns an empty hash if nothing is matched' do
        @user1.disable!
        @user2.disable!
        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq({})
      end

      it 'returns result for a single match' do
        @user1.disable!
        expect(@user2.disabled).to be false

        ca = ConditionalActions.new @config, @test_object
        res = ca.calc_save_option_if check_action_if: true

        expect(res).to eq(
          on_update: {
            do_trigger: 'trigger4'
          }
        )
      end
    end
  end
end
