# List of stuff that needs to be done

1. Now that common parameters are removed need to update the order of rule parameters, also not all are the same.
2. update FirewallParamters.md with a list of incompatible paramters for reference
3. apply local IP to all rules, as optional feature
4. Detect if script ran manually, to be able to reset errors and warning status
5. some rules are missing comments
6. auto detect interfaces
7. CTRL + F and search for "TODO"
8. Implement unique names and groups for rules, -Name and -Group paramter vs -Display*
9. make display names and groups modular for easy search, ie. group - subgroup, Company - Program
10. make possible to apply or enable only rules relevant for current firewall profile
11. make possible to apply rules to remote machine, currently partially supported
12. Function to check executables for signature and virus total hash
13. Count invalid paths in each script
15. Test already loaded rules if pointing to valid program or service, also test for weakness
16. Limit code to 80-100 columns rule, subject to exceptoins
17. Provide following keywords in function comments: .DESCRIPTION .LINK .COMPONENT
18. Access is denied randomly while executing rules, need some check around this
19. Need to see which functions/commands may throw and setup try catch blocks
20. Most program query functions return multiple program instances, need to select latest or add multiple rules.
21. Apply only rules for which executable exists, Test-File function
22. Implement Importing/Exporting rules.
