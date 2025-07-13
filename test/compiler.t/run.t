
  $ . ../testing.sh

  $ compile ../programs/comments.md
  [
    {
      "name": "prelude",
      "cmds": [
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
        ]
      ]
    }
  ]

  $ compile ../programs/jump-links.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Para",
          [
            [
              "LinkJump",
              "jump",
              "One"
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
              "asd"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/code-links.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Run",
          "function runMe() {\n  console.log('hi');\n  interpret([['Para', [['Text', 'Hi!']]]], content,()=>{});\n}"
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
        ]
      ]
    }
  ]

  $ compile ../programs/frontmatter.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "hello"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/tweet-style-choices.md
  [
    {
      "name": "h",
      "cmds": [
        [
          "Run",
          "tweet_style_choices = true;"
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
                  "a"
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
                      "this is later cleared"
                    ],
                    [
                      "Jump",
                      "h"
                    ]
                  ]
                ]
              ],
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
                  "c"
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
              "after"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/tweet-style-choices.md
  [
    {
      "name": "h",
      "cmds": [
        [
          "Run",
          "tweet_style_choices = true;"
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
                  "a"
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
                      "this is later cleared"
                    ],
                    [
                      "Jump",
                      "h"
                    ]
                  ]
                ]
              ],
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
                  "c"
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
              "after"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/meta.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Run",
          "var items = ['Apple', 'Banana', 'Carrot'];"
        ],
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
    }
  ]

  $ compile ../programs/interpolation.md
  [
    {
      "name": "prelude",
      "cmds": [
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
                  "a"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "b"
                ]
              ],
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
      "name": "b",
      "cmds": [
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
                  "c"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "b"
                ]
              ],
              "rest": [],
              "kind": [
                "Consumable",
                "c1"
              ]
            }
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/choices-continue.md
  [
    {
      "name": "prelude",
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
                  "continue"
                ]
              ],
              "code": [],
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
                  "x"
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
        ],
        [
          "Para",
          [
            [
              "Text",
              "here"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/choices-text.md
  [
    {
      "name": "prelude",
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
                  "x"
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
                      "a"
                    ]
                  ]
                ]
              ],
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
                  "y"
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
      "name": "a",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "2"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/choices-nested.md
  [
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
                        "c4"
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
                        "c3"
                      ]
                    }
                  ]
                ]
              ],
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
                "c2"
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
                "c1"
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
    }
  ]

  $ compile ../programs/jump-dynamic.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Run",
          "var items = ['Apple', 'Banana', 'Carrot'];"
        ],
        [
          "Para",
          [
            [
              "JumpDynamic",
              "items[0]"
            ]
          ]
        ]
      ]
    },
    {
      "name": "Apple",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "Apple"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/choices-more.md
  [
    {
      "name": "prelude",
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
                "c0"
              ]
            }
          ]
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
                "c2"
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
                "c1"
              ]
            }
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/choices-copy.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "MetaBlock",
          "internal.scenes['One']"
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
        ]
      ]
    }
  ]

  $ compile ../programs/tunnels.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Para",
          [
            [
              "Tunnel",
              "a"
            ]
          ]
        ],
        [
          "Para",
          [
            [
              "Text",
              "2"
            ]
          ]
        ]
      ]
    },
    {
      "name": "a",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "1"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/tunnels-followed-by-jumps.md
  [
    {
      "name": "prelude",
      "cmds": [
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
                "c0"
              ]
            }
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/spaces.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Choices",
          [],
          [
            {
              "guard": [
                "true"
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
    }
  ]

  $ compile ../programs/inline-and-block-meta.md
  [
    {
      "name": "prelude",
      "cmds": [
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
    }
  ]

  $ compile ../programs/inline-meta-jump.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "hi"
            ],
            [
              "Meta",
              "'there' + jump('a')"
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
      "name": "a",
      "cmds": [
        [
          "Para",
          [
            [
              "Text",
              "b"
            ]
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/block-meta-jump.md
  [
    {
      "name": "prelude",
      "cmds": [
        [
          "MetaBlock",
          "'1'"
        ],
        [
          "MetaBlock",
          "if (true) {\n  '2 `->a`'\n}"
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
      "name": "a",
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
    }
  ]

  $ compile ../programs/choice-break-delimiters.md
  [
    {
      "name": "prelude",
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
                "c0"
              ]
            }
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/choice-break-delimiters.md
  [
    {
      "name": "prelude",
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
                "c0"
              ]
            }
          ]
        ]
      ]
    }
  ]

  $ compile ../programs/nonexistent-section.md
  [
    {
      "name": "prelude",
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
                  "Hello"
                ]
              ],
              "code": [
                [
                  "Jump",
                  "a"
                ]
              ],
              "rest": [],
              "kind": [
                "Consumable",
                "c0"
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
