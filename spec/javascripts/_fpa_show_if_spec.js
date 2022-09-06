//= require app/_fpa_show_if.js
describe('show_if', function () {
  it("tests that all specified fields have a value", function () {

    var res

    var field_def_init = {
      field_a: 2,
      field_b: ['some', 'value'],
      field_c: ''
    }

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: ''
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 3,
      field_b: 'value',
      field_c: ''
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)


    var field_def_init = {
      all: {
        field_a: 2,
        field_b: ['some', 'value'],
        field_c: ''
      }
    }

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: ''
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 3,
      field_b: 'value',
      field_c: ''
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

  });

  it("tests that any specified fields have a value", function () {

    var res

    var field_def_init = {
      any: {
        field_a: 2,
        field_b: ['some', 'value'],
        field_c: ''
      }
    }

    var data = {
      field_a: 2,
      field_b: 'bad value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 3,
      field_b: 'bad value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

  });


  it("tests that not any of the specified fields have a value", function () {

    var res

    var field_def_init = {
      not_any: {
        field_a: 2,
        field_b: ['some', 'value'],
        field_c: ''
      }
    }

    var data = {
      field_a: 2,
      field_b: 'bad value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

    var data = {
      field_a: 3,
      field_b: 'bad value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

  });


  it("tests that not all of the specified fields match", function () {

    var res

    var field_def_init = {
      not_all: {
        field_a: 2,
        field_b: ['some', 'value'],
        field_c: ''
      }
    }

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: ''
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

  });


  it("allows for a condition to be specified", function () {

    var res

    var field_def_init = {
      all: {
        field_a: 2,
        field_b: {
          condition: '<>',
          value: 'a value'
        },
        field_c: 'something'
      }
    }

    var data = {
      field_a: 2,
      field_b: 'bad value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 2,
      field_b: 'a value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)


    var field_def_init = {
      all: {
        field_a: 2,
        field_b: {
          condition: '>=',
          value: 10
        },
        field_c: 'something'
      }
    }

    var data = {
      field_a: 2,
      field_b: 9,
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)


    var data = {
      field_a: 2,
      field_b: 10,
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var field_def_init = {
      all: {
        field_a: 2,
        field_b: {
          condition: '=',
          value: 10
        },
        field_c: 'something'
      }
    }

    var data = {
      field_a: 2,
      field_b: 9,
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

    var data = {
      field_a: 2,
      field_b: 10,
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)
  });


  it("allows for nested conditions", function () {

    var res

    var field_def_init = {
      any: {
        all: {
          field_a: 2,
          field_b: ['some', 'value'],
          field_c: ''
        },
        all_2: {
          field_a: 4,
          field_c: 'another one'
        }
      }
    }

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: 'something'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: ''
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 4,
      field_b: 'anything',
      field_c: 'another one'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)


    var data = {
      field_a: 4,
      field_b: 'anything',
      field_c: 'not another one'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)



    var field_def_init = {
      not_all: {
        any: {
          field_a: 2,
          field_b: ['some', 'value'],
        },
        all_2: {
          field_c: 'another one'
        }
      }
    }

    var data = {
      field_a: 4,
      field_b: 'anything',
      field_c: 'not another one'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 2,
      field_b: 'any value',
      field_c: 'not another one'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 2,
      field_c: 'another one'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)


    var field_def_init = {
      any: {
        all: {
          six_or_more_frequency: null,
          total_score: [0, 1, 2, 3, 4, 5],
          alcohol_frequency: [2, 3, 4]
        },
        not_any: {
          six_or_more_frequency: ''
        }
      }
    }


    var data = {
      alcohol_frequency: 3,
      total_score: 7,
      six_or_more_frequency: 4
    }
    console.log('test')

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      alcohol_frequency: 0,
      total_score: 0,
      six_or_more_frequency: ''
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

  });


  it("tests that any array of values, like current_user_roles can be used for comparison", function () {

    var res

    var field_def_init = {
      not_all: {
        field_a: 2,
        field_b: ['some', 'value'],
        field_c: 'something',
        current_user_roles: 'role4'
      }
    }

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: 'something',
      current_user_roles: ['role1', 'role2', 'role3']
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      field_a: 2,
      field_b: 'value',
      field_c: 'something',
      current_user_roles: ['role1', 'role4', 'role3']
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

  });

  it("tests a generated comparison", function () {

    var res

    // This data is generated by spec/models/redcap/data_dictionaries/branching_logic_spec.rb
    // it 'generates a hash of blocks'
    var field_def_init = {
      "all_3": {
        "all_block_0": {
          "any_0": {
            "aaa": 1,
            "bbb": {
              "condition": ">=",
              "value": 3
            }
          }
        },
        "all_block_2": {
          "any_2": {
            "all_sub_block_2": {
              "any_2": {
                "all_1": {
                  "yesno___1": "1",
                  "test_var": {
                    "condition": "<>",
                    "value": "some (other) 'value'"
                  },
                  "all_dupvar_0": {
                    "test_var": {
                      "condition": "<>",
                      "value": "this value"
                    }
                  }
                },
                "any_1": {
                  "other": "other1"
                }
              }
            },
            "ants": "many"
          }
        }
      }
    }

    var data = {
      aaa: 1,
      yesno___1: '1',
      test_var: 'good val',
      ants: 'none'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      bbb: 7,
      yesno___1: '1',
      test_var: 'good val',
      ants: 'none'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      bbb: 7,
      yesno___1: '7',
      other: 'other1',
      test_var: 'good val',
      ants: 'none'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      bbb: 7,
      yesno___1: '1',
      test_var: 'this value',
      ants: 'many'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(true)

    var data = {
      bbb: 7,
      yesno___1: '1',
      test_var: 'this value',
      ants: 'none'
    }

    res = _fpa.show_if.methods.calc_conditions(field_def_init, data)
    expect(res).toBe(false)

  })


});
