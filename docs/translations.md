# Writing and Translations
There's a lot of text in AAA, varying between single word titles to paragraph descriptions. This document is mostly a place to hold the template for creating tickets to manage the writing workflow.

## Workflow
When creating a pull request containing English text, you must add new entries to the `addon_english.txt` file as opposed to putting them directly into the KV/xml/js/lua/whatever. Pull requests with visible English text outside of this file will not be approved.

* When the pull request is created, link to the ticket filed using the below template before it is approved
* Team members from design, copy, or any other applicable teams approve the English copy
* Once approved, assign/link the ticket to each translation team
* Team members from each language submit translations
* Once all 4 are in, assign/link the ticket to the programming team
* Programmers put the updated copy and translations into the translations files
* Pull request, merge, rejoice.

# Ticket Template
### Single Translation
```markdown
### Request for copy and translations
**Key**: "PUT_KEY_HERE"  
**English copy**: "text"

* [ ] English copy approved

Only begin translations when English text is approved. Add in the complete translation before checking the list item.

 * [ ] Chinese translation: ""
 * [ ] Russian translation: ""
 * [ ] Spanish translation: ""
 * [ ] Portuguese translation: ""
```
### Multiple Translations
Sometimes you create several similar pieces of text at once.

```markdown
### Request for copy and translations
**Key**: "PUT_KEY_HERE"  
**English copy**: "text"  
**Key**: "OTHER_KEY_HERE"  
**English copy**: "text"  
**Key**: "MORE_KEYS"  
**English copy**: "text"  

* [ ] English copy approved
  * [ ] **PUT_KEY_HERE**
  * [ ] **OTHER_KEY_HERE**
  * [ ] **MORE_KEYS**

Only begin translations when English text is approved. Add in the complete translation before checking the list item.

 * [ ] Chinese translation: 
   * [ ] **PUT_KEY_HERE**: "chinese"
   * [ ] **OTHER_KEY_HERE**: "chinese"
   * [ ] **MORE_KEYS**: "chinese"
 * [ ] Russian translation: ""
   * [ ] **PUT_KEY_HERE**: "russian"
   * [ ] **OTHER_KEY_HERE**: "russian"
   * [ ] **MORE_KEYS**: "russian"
 * [ ] Spanish translation: ""
   * [ ] **PUT_KEY_HERE**: "spanish"
   * [ ] **OTHER_KEY_HERE**: "spanish"
   * [ ] **MORE_KEYS**: "spanish"
 * [ ] Portuguese translation: ""
   * [ ] **PUT_KEY_HERE**: "portuguese"
   * [ ] **OTHER_KEY_HERE**: "portuguese"
   * [ ] **MORE_KEYS**: "portuguese"
```
