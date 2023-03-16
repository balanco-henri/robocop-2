*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Archive
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             OperatingSystem
Library             Collections


*** Variables ***
${WEB_URL}                          https://robotsparebinindustries.com/#/robot-order
${DOWNLOAD_URL}                     https://robotsparebinindustries.com/orders.csv
${DOWNLOAD_FILE}                    ${OUTPUT DIR}${/}orders.csv
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${OUTPUT DIR}${/}receipts
${IMAGE_TEMP_OUTPUT_DIRECTORY}=     ${OUTPUT DIR}${/}images


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Loop the orders    ${orders}
    Create a ZIP file of receipt PDF files
    [Teardown]    Close Browser and Clean up


*** Keywords ***
Open the robot order website
    Open Available Browser    ${WEB_URL}

Get orders
    Download    ${DOWNLOAD_URL}    target_file=${DOWNLOAD_FILE}    overwrite=true
    ${orders}=    Read table from CSV    ${DOWNLOAD_FILE}
    RETURN    ${orders}

Loop the orders
    [Arguments]    ${orders}

    FOR    ${row}    IN    @{orders}
        Set Local Variable    ${alert_locator}    css:.alert-danger

        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Run Keyword And Continue On Failure    Submit the order

        ${order_error}=    Is Element Visible    ${alert_locator}

        WHILE    ${order_error}    limit=10
            Log    "Error"
            Sleep    5s
            Run Keyword And Continue On Failure    Submit the order
            ${order_error}=    Is Element Visible    ${alert_locator}
        END
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot image    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END

Close the annoying modal
    Click Element If Visible    css:.btn-danger

Fill the form
    [Arguments]    ${row}

    Wait Until Page Contains Element    css:#order
    Sleep    1s

    Select From List By Value    head    ${row}[Head]
    Page Should Contain Radio Button    body
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[type="number"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button When Visible    //*[@id="preview"]

Check element is loaded and Visible
    [Arguments]    ${locator}
    Does Page Contain Element    ${locator}
    Element Should Be Visible    ${locator}

Submit the order
    Set Local Variable    ${order-locator}    //*[@id="order"]

    Sleep    1s
    Wait Until Keyword Succeeds    3x    2s    Check element is loaded and Visible    ${order-locator}
    Click Button When Visible    ${order-locator}

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Set Local Variable    ${receipt-locator}    //*[@id="receipt"]

    Check element is loaded and Visible    ${receipt-locator}
    Wait Until Element Is Visible    ${receipt-locator}
    ${receipt_html}=    Get Element Attribute    ${receipt-locator}    outerHTML
    Set Local Variable    ${receipt_file}    ${OUTPUT_DIR}${/}receipts${/}order_${order_number}_receipt.pdf
    ${pdf}=    Html To Pdf    ${receipt_html}    ${receipt_file}

    RETURN    ${receipt_file}

Take a screenshot of the robot image
    [Arguments]    ${order_number}

    Wait Until Page Contains Element    id:robot-preview
    Wait Until Element Is Visible    id:robot-preview

    Set Local Variable    ${image_file}    ${OUTPUT_DIR}${/}images${/}order_${order_number}_image.png
    ${screenshot}=    Screenshot
    ...    //*[@id="robot-preview-image"]
    ...    ${image_file}

    RETURN    ${image_file}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}

    File Should Exist    ${pdf}
    File Should Exist    ${screenshot}
    File Should Not Be Empty    ${pdf}
    File Should Not Be Empty    ${screenshot}

    Open Pdf    ${pdf}
    ${files}=    Create List    ${pdf}    ${screenshot}:align=center
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf    ${pdf}

Order another robot
    Set Local Variable    ${another-order-locator}    //*[@id="order-another"]

    Wait Until Page Contains Element    ${another-order-locator}
    Wait Until Element Is Visible    ${another-order-locator}
    Click Button When Visible    ${another-order-locator}

Create a ZIP file of receipt PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Close Browser and Clean up
    Close All Browsers

    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True
    Remove Directory    ${IMAGE_TEMP_OUTPUT_DIRECTORY}    True
