
  $ main test.md | sed -e 's/const data = //g' -e 's/;$//g' | jq .
  [
    {
      "name": "Two",
      "cmds": [
        [
          "Run",
          "var turns = 0;\nfunction on_interact() {\n  turns++;\n}\nvar items = ['Apple', 'Banana', 'Carrot'];\nvar a = items[Math.floor(Math.random()*items.length)];"
        ],
        [
          "Para",
          [
            [
              "Text",
              "Hello "
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
          [
            {
              "guard": [],
              "initial": [
                [
                  "Text",
                  "Go to Scene 1 "
                ]
              ],
              "code": [
                [
                  "Jump",
                  "One"
                ]
              ],
              "rest": [
                "Para",
                [
                  [
                    "Text",
                    " should not show"
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
                  "Say something, then go to Scene 1 "
                ]
              ],
              "code": [
                [
                  "Run",
                  "1"
                ]
              ],
              "rest": [
                "Para",
                [
                  [
                    "Text",
                    " should show. "
                  ],
                  [
                    "Jump",
                    "One"
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
                  "Go to Scene 3 "
                ]
              ],
              "code": [
                [
                  "Jump",
                  "Three"
                ]
              ],
              "rest": [
                "Para",
                []
              ],
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
              "rest": [
                "Para",
                []
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
              "after all"
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
              "Turns: "
            ],
            [
              "Interpolate",
              "turns"
            ]
          ]
        ]
      ]
    },
    {
      "name": "Nested",
      "cmds": []
    }
  ]
