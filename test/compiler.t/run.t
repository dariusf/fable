
  $ fable ../../examples/test.md | sed -e 's/var story = //g' -e 's/;$//g' | jq .
  [
    {
      "name": "Two",
      "cmds": [
        [
          "Run",
          "var items = ['Apple', 'Banana', 'Carrot'];\n// This makes testing tough\n// var a = items[Math.floor(Math.random()*items.length)];\nvar a = items[2-3+1];"
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
              "' '+a"
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
                  "Say something, then go to Scene 1"
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
                  "Tunnel"
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
          "Meta",
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
              "' '"
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
          "Run",
          "render_scene('One');"
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
        ]
      ]
    }
  ]
