# PowerShell Script to Load and Run the XAML Interface

# Load necessary assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Import the Get-BBUsers function
# Import-Module 
Import-Module -Name ".\Get-BBUsers.ps1" -Force

# Function to load XAML
function Load-XamlWindow {
    param (
        [string]$XamlPath
    )
    
    $inputXML = Get-Content $XamlPath -Raw
    $inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
    
    [xml]$xaml = $inputXML
    
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try {
        $window = [Windows.Markup.XamlReader]::Load($reader)
    } catch {
        Write-Host "Unable to load XAML. Error: $_"
        return $null
    }
    
    # Create a dictionary to store the form controls
    $formControls = @{}
    
    # Find all elements with a name
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
        $name = $_.Name
        $element = $window.FindName($name)
        $formControls.Add($name, $element)
    }
    
    return @{
        Window = $window
        Controls = $formControls
    }
}

# Function to run the query based on UI selections
function Run-BBUsersQuery {
    param (
        $Controls
    )
    
    # Clear previous results
    $Controls.dgResults.ItemsSource = $null
    $Controls.txtStatus.Text = "Running query..."
    $Controls.txtConsole.Text = ""
    
    # Get query parameters from UI
    $enabled = $Controls.chkEnabled.IsChecked
    $all = $Controls.chkAll.IsChecked
    $includeEPM = $Controls.chkIncludeEPM.IsChecked
    $includeConsultants = $Controls.chkIncludeConsultants.IsChecked
    
    # Collect selected properties
    $properties = @()
    if ($Controls.chkPropAll.IsChecked) {
        $properties = @('*')
    } else {
        if ($Controls.chkPropName.IsChecked) { $properties += 'Name' }
        if ($Controls.chkPropLastLogon.IsChecked) { $properties += 'LastLogonDate' }
        if ($Controls.chkPropDepartment.IsChecked) { $properties += 'Department' }
        if ($Controls.chkPropCompany.IsChecked) { $properties += 'Company' }
        if ($Controls.chkPropEmployeeID.IsChecked) { $properties += 'EmployeeID' }
        if ($Controls.chkPropOfficePhone.IsChecked) { $properties += 'OfficePhone' }
        if ($Controls.chkPropMobilePhone.IsChecked) { $properties += 'MobilePhone' }
    }
    
    # Prepare parameters for Get-BBUsers
    $params = @{
        Properties = $properties
    }
    
    if ($enabled) { $params.Add('Enabled', $true) }
    if ($all) { $params.Add('All', $true) }
    if ($includeEPM) { $params.Add('IncludeEPM', $true) }
    if ($includeConsultants) { $params.Add('IncludeConsultants', $true) }
    
    # Run the query with verbose output
    try {
        $VerbosePreference = "Continue"
        $output = New-Object System.Text.StringBuilder
        $results = Get-BBUsers @params -Verbose 4>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.VerboseRecord]) {
                [void]$output.AppendLine($_.Message)
            } else {
                $_
            }
        }
        $Controls.txtConsole.Text = $output.ToString()
        $Controls.dgResults.ItemsSource = $results
        $Controls.txtStatus.Text = "Query completed. Found $($results.Count) users."
    } catch {
        $Controls.txtStatus.Text = "Error occurred during query."
        $Controls.txtConsole.Text += "`r`nError: $_"
    } finally {
        $VerbosePreference = "SilentlyContinue"
    }
}

# Function to export results to CSV
function Export-ResultsToCsv {
    param (
        $Controls
    )
    
    if ($Controls.dgResults.ItemsSource -eq $null) {
        $Controls.txtStatus.Text = "No results to export."
        return
    }
    
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "CSV Files (*.csv)|*.csv"
    $saveFileDialog.Title = "Save Results"
    $saveFileDialog.FileName = "BBUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    
    if ($saveFileDialog.ShowDialog() -eq 'OK') {
        try {
            $Controls.dgResults.ItemsSource | Export-Csv -Path $saveFileDialog.FileName -NoTypeInformation
            $Controls.txtStatus.Text = "Results exported to $($saveFileDialog.FileName)"
        } catch {
            $Controls.txtStatus.Text = "Error exporting results."
            $Controls.txtConsole.Text += "`r`nExport Error: $_"
        }
    }
}

# Main script execution
# Save XAML to a file
$xamlContent = @'
<Window x:Class="BBUsersGUI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Boothbay User Management" Height="600" Width="800"
        Background="#F0F0F0">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <TextBlock Grid.Row="0" 
                   Text="Boothbay User Management" 
                   FontSize="24" 
                   FontWeight="Bold" 
                   Margin="0,0,0,15"/>

        <!-- Options Panel -->
        <GroupBox Grid.Row="1" Header="Query Options" Margin="0,0,0,10">
            <Grid Margin="10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Left Column -->
                <StackPanel Grid.Column="0" Grid.Row="0">
                    <CheckBox x:Name="chkEnabled" Content="Enabled Users Only" IsChecked="True" Margin="0,5"/>
                    <CheckBox x:Name="chkAll" Content="All Users" Margin="0,5"/>
                </StackPanel>

                <!-- Right Column -->
                <StackPanel Grid.Column="1" Grid.Row="0">
                    <CheckBox x:Name="chkIncludeEPM" Content="Include EPM" Margin="0,5"/>
                    <CheckBox x:Name="chkIncludeConsultants" Content="Include Consultants" Margin="0,5"/>
                </StackPanel>

                <!-- Properties Selection -->
                <GroupBox Grid.Column="0" Grid.ColumnSpan="2" Grid.Row="1" Header="Properties to Display" Margin="0,10">
                    <WrapPanel Margin="5">
                        <CheckBox x:Name="chkPropName" Content="Name" IsChecked="True" Margin="5"/>
                        <CheckBox x:Name="chkPropLastLogon" Content="LastLogonDate" IsChecked="True" Margin="5"/>
                        <CheckBox x:Name="chkPropDepartment" Content="Department" IsChecked="True" Margin="5"/>
                        <CheckBox x:Name="chkPropCompany" Content="Company" IsChecked="True" Margin="5"/>
                        <CheckBox x:Name="chkPropEmployeeID" Content="EmployeeID" Margin="5"/>
                        <CheckBox x:Name="chkPropOfficePhone" Content="OfficePhone" Margin="5"/>
                        <CheckBox x:Name="chkPropMobilePhone" Content="MobilePhone" Margin="5"/>
                        <CheckBox x:Name="chkPropAll" Content="All Properties (*)" Margin="5"/>
                    </WrapPanel>
                </GroupBox>

                <!-- Buttons -->
                <StackPanel Grid.Column="0" Grid.ColumnSpan="2" Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button x:Name="btnRun" Content="Run Query" Width="100" Height="30" Margin="5"/>
                    <Button x:Name="btnExport" Content="Export to CSV" Width="100" Height="30" Margin="5"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- Results DataGrid -->
        <GroupBox Grid.Row="2" Header="Results" Margin="0,0,0,10">
            <DataGrid x:Name="dgResults" 
                      AutoGenerateColumns="True" 
                      IsReadOnly="True"
                      AlternatingRowBackground="#F9F9F9"
                      BorderThickness="1"
                      VerticalScrollBarVisibility="Auto"
                      HorizontalScrollBarVisibility="Auto"/>
        </GroupBox>

        <!-- Status Bar -->
        <StatusBar Grid.Row="3" Height="25">
            <StatusBarItem>
                <TextBlock x:Name="txtStatus" Text="Ready"/>
            </StatusBarItem>
        </StatusBar>

        <!-- Console Output -->
        <GroupBox Grid.Row="4" Header="Console Output" Height="100">
            <TextBox x:Name="txtConsole" 
                     IsReadOnly="True" 
                     TextWrapping="Wrap"
                     VerticalScrollBarVisibility="Auto"
                     Background="#F5F5F5"
                     FontFamily="Consolas"/>
        </GroupBox>
    </Grid>
</Window>
'@

$xamlPath = "$PSScriptRoot\BBUsersGUI.xaml"
Set-Content -Path $xamlPath -Value $xamlContent

# Load the XAML interface
$form = Load-XamlWindow -XamlPath $xamlPath
if ($form -eq $null) {
    Write-Host "Failed to load the interface."
    exit
}

$window = $form.Window
$controls = $form.Controls

# Set up event handlers
$controls.btnRun.Add_Click({
    Run-BBUsersQuery -Controls $controls
})

$controls.btnExport.Add_Click({
    Export-ResultsToCsv -Controls $controls
})

$controls.chkAll.Add_Checked({
    if ($controls.chkAll.IsChecked) {
        $controls.chkIncludeEPM.IsChecked = $true
        $controls.chkIncludeConsultants.IsChecked = $true
        $controls.chkIncludeEPM.IsEnabled = $false
        $controls.chkIncludeConsultants.IsEnabled = $false
    }
})

$controls.chkAll.Add_Unchecked({
    $controls.chkIncludeEPM.IsEnabled = $true
    $controls.chkIncludeConsultants.IsEnabled = $true
})

$controls.chkPropAll.Add_Checked({
    if ($controls.chkPropAll.IsChecked) {
        $controls.chkPropName.IsEnabled = $false
        $controls.chkPropLastLogon.IsEnabled = $false
        $controls.chkPropDepartment.IsEnabled = $false
        $controls.chkPropCompany.IsEnabled = $false
        $controls.chkPropEmployeeID.IsEnabled = $false
        $controls.chkPropOfficePhone.IsEnabled = $false
        $controls.chkPropMobilePhone.IsEnabled = $false
    }
})

$controls.chkPropAll.Add_Unchecked({
    $controls.chkPropName.IsEnabled = $true
    $controls.chkPropLastLogon.IsEnabled = $true
    $controls.chkPropDepartment.IsEnabled = $true
    $controls.chkPropCompany.IsEnabled = $true
    $controls.chkPropEmployeeID.IsEnabled = $true
    $controls.chkPropOfficePhone.IsEnabled = $true
    $controls.chkPropMobilePhone.IsEnabled = $true
})

# Show the window
$window.ShowDialog() | Out-Null
