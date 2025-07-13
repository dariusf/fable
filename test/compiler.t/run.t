
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
              "kind": [
                "Consumable",
                "c14"
              ]
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
              "kind": [
                "Consumable",
                "c13"
              ]
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
              "kind": [
                "Consumable",
                "c12"
              ]
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
              "kind": [
                "Consumable",
                "c11"
              ]
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
              "kind": [
                "Consumable",
                "c10"
              ]
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
              "kind": [
                "Consumable",
                "c9"
              ]
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
              "kind": [
                "Consumable",
                "c8"
              ]
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
              "kind": [
                "Consumable",
                "c7"
              ]
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
              "kind": [
                "Consumable",
                "c6"
              ]
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
              "kind": [
                "Consumable",
                "c5"
              ]
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
              "kind": [
                "Consumable",
                "c4"
              ]
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
              "kind": [
                "Consumable",
                "c3"
              ]
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
              "kind": [
                "Consumable",
                "c2"
              ]
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
              "kind": [
                "Consumable",
                "c1"
              ]
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
              "kind": [
                "Consumable",
                "c0"
              ]
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
                      "kind": [
                        "Consumable",
                        "c19"
                      ]
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
                      "kind": [
                        "Consumable",
                        "c18"
                      ]
                    }
                  ]
                ]
              ],
              "kind": [
                "Consumable",
                "c20"
              ]
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
              "kind": [
                "Consumable",
                "c17"
              ]
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
              "kind": [
                "Consumable",
                "c16"
              ]
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
              "kind": [
                "Consumable",
                "c15"
              ]
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
              "kind": [
                "Consumable",
                "c22"
              ]
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
              "kind": [
                "Consumable",
                "c21"
              ]
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
              "kind": [
                "Consumable",
                "c23"
              ]
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
              "kind": [
                "Consumable",
                "c24"
              ]
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
              "kind": [
                "Consumable",
                "c25"
              ]
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
              "kind": [
                "Consumable",
                "c26"
              ]
            }
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/consumable-choices.md
  [
    {
      "name": "b",
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
                  "c1"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "c"
                ]
              ],
              "rest": [],
              "kind": [
                "Consumable",
                "c1"
              ]
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "c2"
                ]
              ],
              "code": [],
              "rest": [],
              "kind": [
                "Consumable",
                "c0"
              ]
            }
          ]
        ]
      ]
    },
    {
      "name": "c",
      "cmds": [
        [
          "Para",
          [
            [
              "Jump",
              "b"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/sticky-choices.md
  [
    {
      "name": "b",
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
                  "c1"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "c"
                ]
              ],
              "rest": [],
              "kind": [
                "Sticky"
              ]
            },
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "c2"
                ]
              ],
              "code": [],
              "rest": [],
              "kind": [
                "Consumable",
                "c0"
              ]
            }
          ]
        ]
      ]
    },
    {
      "name": "c",
      "cmds": [
        [
          "Para",
          [
            [
              "Jump",
              "b"
            ]
          ]
        ]
      ]
    }
  ]
