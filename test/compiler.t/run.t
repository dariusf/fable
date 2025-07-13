
  $ . ../testing.sh

  $ compile ../programs/test.md
  [
    {
      "name": "Two",
      "cmds": [
        [
          "Run",
          "tweet_style_choices = false;\nvar items = ['Apple', 'Banana', 'Carrot'];\n// This makes testing tough\n// var a = items[Math.floor(Math.random()*items.length)];\nvar a = items[2-3+1];"
        ],
        [
          "Para",
          [
            [
              "Text",
              "Hello"
            ],
            [
              "Interpolate",
              "a"
            ],
            [
              "Text",
              "!"
            ]
          ]
        ],
        [
          "Run",
          "function runMe() {\n  console.log('hi');\n  interpret([['Para', [['Text', 'Hi!']]]], content,()=>{});\n}"
        ],
        [
          "Para",
          [
            [
              "Text",
              "inline comments"
            ],
            [
              "Verbatim",
              "<i>don't</i>"
            ],
            [
              "Text",
              "appear"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "LinkJump",
              "jump",
              "One"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "LinkCode",
              "code",
              "runMe"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "Make a choice:"
            ]
          ]
        ],
        [
          "Choices",
          [],
          [
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Go to Scene 1"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "One"
                ]
              ],
              "rest": [
                [
                  "Para",
                  [
                    [
                      "Text",
                      "should not show"
                    ]
                  ]
                ]
              ],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Say something, then to Scene 1"
                ]
              ],
              "code": [
                [
                  "Run",
                  "1"
                ]
              ],
              "rest": [
                [
                  "Para",
                  [
                    [
                      "Text",
                      "should show."
                    ],
                    [
                      "Jump",
                      "One"
                    ]
                  ]
                ]
              ],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Go to Scene 3"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "Three"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Continue"
                ]
              ],
              "code": [],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Nested lists"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "Nested"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Copy"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "Copy"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "More"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "More"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Jump dynamic"
                ]
              ],
              "code": [
                [
                  "JumpDynamic",
                  "items[0]"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Tunnel!"
                ]
              ],
              "code": [
                [
                  "Tunnel",
                  "Tunnel"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Tunnels followed by jumps"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "tunnel_test"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Spaces"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "Spaces"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Inline and block meta"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "InlineBlockMeta"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Inline meta jump"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "InlineMetaJump"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Block meta jump"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "BlockMetaJump"
                ]
              ],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Choice break delimiters"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "ChoiceBreakDelimiters"
                ]
              ],
              "rest": [],
              "sticky": false
            }
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "End of first scene"
            ]
          ]
        ]
      ]
    },
    {
      "name": "One",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "text from Scene 1"
            ]
          ]
        ],
        [
          "MetaBlock",
          "items.map(i => `- ${i}`).join('\\n') + `\n\n<details>\n  <summary>Click me</summary>\n  This was hidden\n</details>`"
        ]
      ]
    },
    {
      "name": "Three",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "text from Scene 3"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "Turns:"
            ],
            [
              "Interpolate",
              "internal.turns"
            ]
          ]
        ]
      ]
    },
    {
      "name": "Nested",
      "cmds": [
        [
          "Choices",
          [],
          [
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Choice 1"
                ]
              ],
              "code": [
                [
                  "Run",
                  "1"
                ]
              ],
              "rest": [
                [
                  "Choices",
                  [],
                  [
                    {
                      "guard": [],
                      "initial": [
                        [
                          "Text",
                          "Nested choice. Did you choose choice 1?"
                        ]
                      ],
                      "code": [
                        [
                          "Run",
                          "1"
                        ]
                      ],
                      "rest": [],
                      "sticky": false
                    },
                    {
                      "guard": [],
                      "initial": [
                        [
                          "Text",
                          "Or not?"
                        ]
                      ],
                      "code": [
                        [
                          "Run",
                          "1"
                        ]
                      ],
                      "rest": [],
                      "sticky": false
                    }
                  ]
                ]
              ],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Choice 2"
                ]
              ],
              "code": [
                [
                  "Run",
                  "1"
                ]
              ],
              "rest": [
                [
                  "Para",
                  [
                    [
                      "Text",
                      "after"
                    ],
                    [
                      "Break"
                    ],
                    [
                      "Text",
                      "break"
                    ]
                  ]
                ]
              ],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Choice 3"
                ]
              ],
              "code": [
                [
                  "Run",
                  "1"
                ]
              ],
              "rest": [
                [
                  "Para",
                  [
                    [
                      "Text",
                      "A paragraph"
                    ]
                  ]
                ]
              ],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Choice 4"
                ]
              ],
              "code": [
                [
                  "Run",
                  "1"
                ]
              ],
              "rest": [
                [
                  "Run",
                  "console.log('you chose choice 4');"
                ]
              ],
              "sticky": false
            }
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "Right before going back to Nested"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Jump",
              "Nested"
            ]
          ]
        ]
      ]
    },
    {
      "name": "Copy",
      "cmds": [
        [
          "MetaBlock",
          "internal.scenes['One']"
        ]
      ]
    },
    {
      "name": "Some choices",
      "cmds": [
        [
          "Choices",
          [],
          [
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "a"
                ]
              ],
              "code": [],
              "rest": [],
              "sticky": false
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "b"
                ]
              ],
              "code": [],
              "rest": [],
              "sticky": false
            }
          ]
        ]
      ]
    },
    {
      "name": "More",
      "cmds": [
        [
          "Choices",
          [
            [
              "true",
              "Some choices"
            ]
          ],
          [
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Hi"
                ]
              ],
              "code": [],
              "rest": [],
              "sticky": false
            }
          ]
        ]
      ]
    },
    {
      "name": "Apple",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "Para",
          [
            [
              "Text",
              "Apple scene"
            ]
          ]
        ]
      ]
    },
    {
      "name": "Tunnel",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "Para",
          [
            [
              "Text",
              "Tunnel"
            ]
          ]
        ]
      ]
    },
    {
      "name": "Spaces",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "Choices",
          [],
          [
            {
              "guard": [
                "a"
              ],
              "initial": [
                [
                  "Text",
                  "choice text"
                ]
              ],
              "code": [
                [
                  "Run",
                  "1"
                ]
              ],
              "rest": [
                [
                  "Para",
                  [
                    [
                      "Text",
                      "code after"
                    ]
                  ]
                ]
              ],
              "sticky": false
            }
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "\"Hi,"
            ],
            [
              "Interpolate",
              "'A'"
            ],
            [
              "Text",
              ",\" he said."
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "\""
            ],
            [
              "Interpolate",
              "'Edge case'"
            ],
            [
              "Text",
              "\" here"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Interpolate",
              "'A'"
            ],
            [
              "Text",
              "'s thing"
            ]
          ]
        ]
      ]
    },
    {
      "name": "tunnel_test",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "Para",
          [
            [
              "Text",
              "before"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Tunnel",
              "tunnel_test_a"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "after"
            ]
          ]
        ]
      ]
    },
    {
      "name": "tunnel_test_a",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "a"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Jump",
              "tunnel_test_b"
            ]
          ]
        ]
      ]
    },
    {
      "name": "tunnel_test_b",
      "cmds": [
        [
          "Choices",
          [],
          [
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "b"
                ]
              ],
              "code": [],
              "rest": [],
              "sticky": false
            }
          ]
        ]
      ]
    },
    {
      "name": "InlineBlockMeta",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "Para",
          [
            [
              "Text",
              "interpolation"
            ],
            [
              "Interpolate",
              "'1'"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "inline meta"
            ],
            [
              "Meta",
              "'1'"
            ]
          ]
        ],
        [
          "MetaBlock",
          "'block meta'"
        ]
      ]
    },
    {
      "name": "InlineMetaJump",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "Para",
          [
            [
              "Text",
              "hi"
            ],
            [
              "Meta",
              "'there' + jump('Some choices')"
            ],
            [
              "Text",
              "!"
            ]
          ]
        ]
      ]
    },
    {
      "name": "BlockMetaJump",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "MetaBlock",
          "'1'"
        ],
        [
          "MetaBlock",
          "if (true) {\n  '2 `->BlockMetaJump1`'\n}"
        ],
        [
          "Para",
          [
            [
              "Text",
              "should not show"
            ]
          ]
        ]
      ]
    },
    {
      "name": "BlockMetaJump1",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "3"
            ]
          ]
        ]
      ]
    },
    {
      "name": "ChoiceBreakDelimiters",
      "cmds": [
        [
          "Run",
          "clear()"
        ],
        [
          "Choices",
          [],
          [
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "asd"
                ]
              ],
              "code": [
                [
                  "Break"
                ]
              ],
              "rest": [
                [
                  "Para",
                  [
                    [
                      "Text",
                      "selected"
                    ]
                  ]
                ]
              ],
              "sticky": false
            }
          ]
        ]
      ]
    }
  ]
