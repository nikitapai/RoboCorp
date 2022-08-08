*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Excel.Files
Library             RPA.Archive
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs


*** Variables ***
${Receipt_Folder_Path}=         ${OUTPUT_DIR}${/}Receipts
${Screenshot_Folder_Path}=      ${OUTPUT_DIR}${/}Screenshots


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open Robot site
    Download the orders csv file
    Fill the form using the data from the csv file
    Create zip file of receipts
    [Teardown]    Close the browser


*** Keywords ***
Open Robot site
    Add heading    Input URL
    Add text    Please provide URL to open the site
    Add text input    name=url    placeholder=URL to open the site
    ${result}=    Run dialog
    Open Available Browser    ${result.url}    maximized=TRUE
    # Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=TRUE

Close pop up
    Click Button    OK
    Wait Until Page Contains Element    id:head

Download the orders csv file
    ${secret}=    Get Secret    csv_url
    Download    ${secret}[url]    overwrite=TRUE

Fill and submit the order for one robot
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    #${legs}=    Get Element Attribute    class:form-control    innerhtml
    #Select From List By Value    label:3. Legs:    ${order}[Legs]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Fill the form using the data from the csv file
    ${orders_rep}=    Read table from CSV    path=orders.csv    header=True
    FOR    ${order}    IN    @{orders_rep}
        Wait until keyword succeeds    10x    5s    Close pop up
        Fill and submit the order for one robot    ${order}
        Preview the robot
        ${pdf}=    Wait Until Keyword Succeeds    8x    5s    Store receipt as PDF file    ${order}[Order number]
        ${screenshot}=    Take screenshot of the robot    ${order}[Order number]
        Embed screenshot in PDF    ${screenshot}    ${pdf}
        Order next robot
    END

Preview the robot
    Click Button    Preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Click Button    order

Store receipt as PDF file
    [Arguments]    ${order_number}
    Submit the order
    Wait Until Page Contains Element    id:receipt    timeout=15
    ${pdf_html}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${pdf}    ${Receipt_Folder_Path}${/}receipt_${order_number}_.pdf
    Html To Pdf    ${pdf_html}    ${pdf}
    RETURN    ${pdf}

Take screenshot of the robot
    [Arguments]    ${order_number}
    Set Local Variable    ${screenshot}    ${Screenshot_Folder_Path}${/}robot preview ${order_number}_.png
    ${scrn}=    Screenshot    id:robot-preview-image    ${screenshot}
    RETURN    ${screenshot}

Embed screenshot in PDF
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${img_list}=    Create List    ${screenshot}
    Add Files To Pdf    ${img_list}    ${pdf}    append=TRUE
    #Close Pdf    ${pdf}

Order next robot
    Click Button    Order another robot
    # Set Wait Time    1.0

Create zip file of receipts
    Archive Folder With Zip    ${Receipt_Folder_Path}${/}    ${OUTPUT_DIR}${/}orders.zip

Close the browser
    #Remove Directory    ${Receipt_Folder_Path}${/}
    #Remove Directory    ${Screenshot_Folder_Path}${/}
    Close Browser
