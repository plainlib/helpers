unit DialogUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Forms,
  Controls,
  StdCtrls,
  CheckLst,
  SysUtils,
  Graphics,
  Classes,
  Grids,
  ValEdit;

type
  // Options that control the behavior of the combo dialog
  TComboQueryOption = (cqoEditable, cqoAutoComplete);
  TComboQueryOptions = set of TComboQueryOption;

type
  TDialogUtils = class
  public
    // Shows a lightweight modal input dialog with OK/Cancel; returns True and updates AValue on OK.
    // When ANumeric is True, only digits can be entered.
    class function InputQueryLite(const ACaption, APrompt: string; var AValue: string; ANumeric: boolean = False): boolean;

    // Shows a lightweight modal dialog with a combo box and OK/Cancel; displays AItems and returns the value from AValues in AValue on OK.
    class function ComboQueryLite(const ACaption, APrompt: string; AItems: TStrings; AValues: TStrings;
      var AValue: string; AOptions: TComboQueryOptions = []; AWidth: integer = 350): boolean;

    // Shows a lightweight modal dialog with a check list box and OK/Cancel; displays AItems and returns the values from AValues for the checked rows in ASelectedValues on OK.
    class function CheckListQueryLite(const ACaption, APrompt: string; AItems: TStrings; AValues: TStrings;
      var ASelectedValues: TStringArray; AOptions: TComboQueryOptions = []; AWidth: integer = 400; AHeight: integer = 350): boolean;

    // Shows a table editor for TStringList values and returns a new list on OK.
    // When AReadOnly is True, the list is displayed without editing.
    class function StringListQueryLite(const ACaption: string; AValues: TStrings; AReadOnly: boolean = False;
      AWidth: integer = 600; AHeight: integer = 450; ANameColumnWidth: integer = 180; GridLineColor: TColor = clNone;
      AlternateColor: TColor = clNone): TStringList;
  end;

implementation

{%Region -fold TCheckListFilterHelper}

type
  { Filters the checklist by text while keeping per-item check states. }
  TCheckListFilterHelper = class
  private
    FFilterEdit: TEdit;
    FInputList: TCheckListBox;
    FSourceItems: TStrings;
    FSourceValues: TStrings;
    FCheckStates: array of boolean;
    FVisibleToSource: array of integer;
    procedure FilterChange(Sender: TObject);
    procedure RebuildFilteredList;
  public
    constructor Create(AFilterEdit: TEdit; AInputList: TCheckListBox; ASourceItems, ASourceValues: TStrings;
      const AInitialSelected: TStringArray);
    destructor Destroy; override;
    function CollectSelectedValues: TStringArray;
  end;

constructor TCheckListFilterHelper.Create(AFilterEdit: TEdit; AInputList: TCheckListBox; ASourceItems, ASourceValues: TStrings;
  const AInitialSelected: TStringArray);
var
  I: integer = 0;
  J: integer = 0;
  Found: boolean = False;
begin
  inherited Create;
  FFilterEdit := AFilterEdit;
  FInputList := AInputList;
  FSourceItems := TStringList.Create;
  FSourceItems.Assign(ASourceItems);
  FSourceValues := TStringList.Create;
  FSourceValues.Assign(ASourceValues);
  // Initialize the check state for every source item
  SetLength(FCheckStates, FSourceItems.Count);
  for I := 0 to FSourceItems.Count - 1 do
  begin
    Found := False;
    for J := 0 to High(AInitialSelected) do
      if FSourceValues[I] = AInitialSelected[J] then
      begin
        Found := True;
        Break;
      end;
    FCheckStates[I] := Found;
  end;
  RebuildFilteredList;
  FFilterEdit.OnChange := @FilterChange;
end;

destructor TCheckListFilterHelper.Destroy;
begin
  FFilterEdit.OnChange := nil;
  FSourceItems.Free;
  FSourceValues.Free;
  inherited Destroy;
end;

procedure TCheckListFilterHelper.FilterChange(Sender: TObject);
var
  I: integer = 0;
begin
  // Save current visible check states before rebuilding the list
  for I := 0 to FInputList.Count - 1 do
    FCheckStates[FVisibleToSource[I]] := FInputList.Checked[I];
  RebuildFilteredList;
end;

procedure TCheckListFilterHelper.RebuildFilteredList;
var
  SearchText: string = '';
  I: integer = 0;
  VisibleCount: integer = 0;
begin
  SearchText := LowerCase(Trim(FFilterEdit.Text));
  FInputList.Items.BeginUpdate;
  try
    FInputList.Items.Clear;
    SetLength(FVisibleToSource, 0);
    VisibleCount := 0;
    for I := 0 to FSourceItems.Count - 1 do
    begin
      if (SearchText = '') or (Pos(SearchText, LowerCase(FSourceItems[I])) > 0) then
      begin
        SetLength(FVisibleToSource, VisibleCount + 1);
        FInputList.Items.Add(FSourceItems[I]);
        FInputList.Checked[VisibleCount] := FCheckStates[I];
        FVisibleToSource[VisibleCount] := I;
        Inc(VisibleCount);
      end;
    end;
  finally
    FInputList.Items.EndUpdate;
  end;
end;

function TCheckListFilterHelper.CollectSelectedValues: TStringArray;
var
  I: integer = 0;
  SelCount: integer = 0;
begin
  Result := [];
  // Sync pending UI check states before collecting
  for I := 0 to FInputList.Count - 1 do
    FCheckStates[FVisibleToSource[I]] := FInputList.Checked[I];
  SelCount := 0;
  for I := 0 to High(FCheckStates) do
    if FCheckStates[I] then
      Inc(SelCount);
  SetLength(Result, SelCount);
  SelCount := 0;
  for I := 0 to High(FCheckStates) do
    if FCheckStates[I] then
    begin
      Result[SelCount] := FSourceValues[I];
      Inc(SelCount);
    end;
end;

{%EndRegion}

{%Region -fold TDialogUtils}

class function TDialogUtils.InputQueryLite(const ACaption, APrompt: string; var AValue: string; ANumeric: boolean = False): boolean;
var
  InputForm: TForm;
  PromptLabel: TLabel;
  InputEdit: TEdit;
  BtnOK, BtnCancel: TButton;
begin
  Result := False;

  // Create the form dynamically
  InputForm := TForm.Create(nil);
  try
    InputForm.Caption := ACaption;
    InputForm.Position := poScreenCenter;
    InputForm.BorderStyle := bsDialog;
    InputForm.Width := InputForm.Scale96ToForm(350);

    // Create the prompt label
    PromptLabel := TLabel.Create(InputForm);
    PromptLabel.Parent := InputForm;
    PromptLabel.Caption := APrompt;
    PromptLabel.Left := InputForm.Scale96ToForm(12);
    PromptLabel.Top := InputForm.Scale96ToForm(12);
    PromptLabel.AutoSize := True;

    // Create the input field tightly below the label
    InputEdit := TEdit.Create(InputForm);
    InputEdit.Parent := InputForm;
    InputEdit.Left := InputForm.Scale96ToForm(12);
    InputEdit.Top := PromptLabel.Top + PromptLabel.Height + InputForm.Scale96ToForm(10);
    InputEdit.Width := InputForm.ClientWidth - InputForm.Scale96ToForm(24);
    InputEdit.Text := AValue;
    InputEdit.NumbersOnly := ANumeric;

    // Create the OK button tight below the input field
    BtnOK := TButton.Create(InputForm);
    BtnOK.Parent := InputForm;
    BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOk;
    BtnOK.Default := True; // Triggers on Enter key
    BtnOK.Width := InputForm.Scale96ToForm(75);
    BtnOK.Height := InputForm.Scale96ToForm(25);
    BtnOK.Top := InputEdit.Top + InputEdit.Height + InputForm.Scale96ToForm(12);
    BtnOK.Left := InputForm.ClientWidth - (BtnOK.Width * 2) - InputForm.Scale96ToForm(18);

    // Create the Cancel button next to OK
    BtnCancel := TButton.Create(InputForm);
    BtnCancel.Parent := InputForm;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True; // Triggers on Esc key
    BtnCancel.Width := InputForm.Scale96ToForm(75);
    BtnCancel.Height := InputForm.Scale96ToForm(25);
    BtnCancel.Top := BtnOK.Top;
    BtnCancel.Left := InputForm.ClientWidth - BtnCancel.Width - InputForm.Scale96ToForm(12);

    // Dynamically adjust form height to fit controls snugly
    InputForm.ClientHeight := BtnOK.Top + BtnOK.Height + InputForm.Scale96ToForm(12);

    // Show the dialog and check the result
    if InputForm.ShowModal = mrOk then
    begin
      AValue := InputEdit.Text;
      Result := True;
    end;
  finally
    InputForm.Free;
  end;
end;

class function TDialogUtils.ComboQueryLite(const ACaption, APrompt: string; AItems: TStrings; AValues: TStrings;
  var AValue: string; AOptions: TComboQueryOptions = []; AWidth: integer = 350): boolean;
var
  InputForm: TForm = nil;
  PromptLabel: TLabel = nil;
  InputCombo: TComboBox = nil;
  BtnOK: TButton = nil;
  BtnCancel: TButton = nil;
  SelIdx: integer = -1;
begin
  Result := False;

  // Validate that both lists are provided and have the same size
  if (AItems = nil) or (AValues = nil) then
    Exit;
  if AItems.Count <> AValues.Count then
    Exit;

  // Create the form dynamically
  InputForm := TForm.Create(nil);
  try
    InputForm.Caption := ACaption;
    InputForm.Position := poScreenCenter;
    InputForm.BorderStyle := bsDialog;
    InputForm.Width := InputForm.Scale96ToForm(AWidth);

    // Create the prompt label
    PromptLabel := TLabel.Create(InputForm);
    PromptLabel.Parent := InputForm;
    PromptLabel.Caption := APrompt;
    PromptLabel.Left := InputForm.Scale96ToForm(12);
    PromptLabel.Top := InputForm.Scale96ToForm(12);
    PromptLabel.AutoSize := True;

    // Create the combo box tightly below the label
    InputCombo := TComboBox.Create(InputForm);
    InputCombo.Parent := InputForm;
    InputCombo.Left := InputForm.Scale96ToForm(12);
    InputCombo.Top := PromptLabel.Top + PromptLabel.Height + InputForm.Scale96ToForm(10);
    InputCombo.Width := InputForm.ClientWidth - InputForm.Scale96ToForm(24);
    InputCombo.DropDownCount := 20;

    // Apply the editable option, otherwise the combo is select-only
    if cqoEditable in AOptions then
      InputCombo.Style := csDropDown
    else
      InputCombo.Style := csDropDownList;
    // Apply the autocomplete option, it works only in editable mode
    InputCombo.AutoComplete := cqoAutoComplete in AOptions;

    InputCombo.Items.Assign(AItems);

    // Preselect the item whose value matches AValue if possible
    SelIdx := AValues.IndexOf(AValue);
    if SelIdx >= 0 then
      InputCombo.ItemIndex := SelIdx
    else if (cqoEditable in AOptions) and (AValue <> '') then
      InputCombo.Text := AValue
    else if InputCombo.Items.Count > 0 then
      InputCombo.ItemIndex := 0;

    // Create the OK button tight below the combo box
    BtnOK := TButton.Create(InputForm);
    BtnOK.Parent := InputForm;
    BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOk;
    BtnOK.Default := True; // Triggers on Enter key
    BtnOK.Width := InputForm.Scale96ToForm(75);
    BtnOK.Height := InputForm.Scale96ToForm(25);
    BtnOK.Top := InputCombo.Top + InputCombo.Height + InputForm.Scale96ToForm(12);
    BtnOK.Left := InputForm.ClientWidth - (BtnOK.Width * 2) - InputForm.Scale96ToForm(18);

    // Create the Cancel button next to OK
    BtnCancel := TButton.Create(InputForm);
    BtnCancel.Parent := InputForm;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True; // Triggers on Esc key
    BtnCancel.Width := InputForm.Scale96ToForm(75);
    BtnCancel.Height := InputForm.Scale96ToForm(25);
    BtnCancel.Top := BtnOK.Top;
    BtnCancel.Left := InputForm.ClientWidth - BtnCancel.Width - InputForm.Scale96ToForm(12);

    // Dynamically adjust form height to fit controls snugly
    InputForm.ClientHeight := BtnOK.Top + BtnOK.Height + InputForm.Scale96ToForm(12);

    // Show the dialog and check the result
    if InputForm.ShowModal = mrOk then
    begin
      if InputCombo.ItemIndex >= 0 then
      begin
        AValue := AValues[InputCombo.ItemIndex];
        Result := True;
      end
      else if (cqoEditable in AOptions) and (Trim(InputCombo.Text) <> '') then
      begin
        AValue := Trim(InputCombo.Text);
        Result := True;
      end;
    end;
  finally
    InputForm.Free;
  end;
end;

class function TDialogUtils.CheckListQueryLite(const ACaption, APrompt: string; AItems: TStrings; AValues: TStrings;
  var ASelectedValues: TStringArray; AOptions: TComboQueryOptions = []; AWidth: integer = 400; AHeight: integer = 350): boolean;
var
  InputForm: TForm = nil;
  PromptLabel: TLabel = nil;
  FilterEdit: TEdit = nil;
  InputList: TCheckListBox = nil;
  FilterHelper: TCheckListFilterHelper = nil;
  BtnOK: TButton = nil;
  BtnCancel: TButton = nil;
  MinHeight: integer = 0;
begin
  Result := False;
  SetLength(ASelectedValues, 0);

  // Validate that both lists are provided and have the same size
  if (AItems = nil) or (AValues = nil) then
    Exit;
  if AItems.Count <> AValues.Count then
    Exit;

  InputForm := TForm.Create(nil);
  try
    // Scale design pixel sizes to the current DPI of the form
    AWidth := InputForm.Scale96ToForm(AWidth);
    AHeight := InputForm.Scale96ToForm(AHeight);

    // Keep the dialog usable even if a too small height was requested
    MinHeight := InputForm.Scale96ToForm(80);
    if AHeight < MinHeight then
      AHeight := MinHeight;

    InputForm.Caption := ACaption;
    InputForm.Position := poScreenCenter;
    // Resizable border so the user can drag the edges with the mouse
    InputForm.BorderStyle := bsSizeable;
    InputForm.Width := AWidth;
    // Do not let the user shrink the form below a usable size
    InputForm.Constraints.MinWidth := InputForm.Scale96ToForm(240);
    InputForm.Constraints.MinHeight := InputForm.Scale96ToForm(180);

    // Create the prompt label docked to the top of the form
    PromptLabel := TLabel.Create(InputForm);
    PromptLabel.Parent := InputForm;
    PromptLabel.Caption := APrompt;
    PromptLabel.AutoSize := True;
    PromptLabel.Align := alTop;
    PromptLabel.BorderSpacing.Left := InputForm.Scale96ToForm(12);
    PromptLabel.BorderSpacing.Top := InputForm.Scale96ToForm(12);
    PromptLabel.BorderSpacing.Right := InputForm.Scale96ToForm(12);
    PromptLabel.BorderSpacing.Bottom := InputForm.Scale96ToForm(6);

    // Create the filter edit docked just below the prompt label
    FilterEdit := TEdit.Create(InputForm);
    FilterEdit.Parent := InputForm;
    FilterEdit.Align := alTop;
    FilterEdit.TextHint := 'Filter...';
    FilterEdit.BorderSpacing.Top := InputForm.Scale96ToForm(6);
    FilterEdit.BorderSpacing.Left := InputForm.Scale96ToForm(12);
    FilterEdit.BorderSpacing.Right := InputForm.Scale96ToForm(12);
    FilterEdit.BorderSpacing.Bottom := InputForm.Scale96ToForm(6);
    FilterEdit.TabOrder := 0;

    // Create the checklist box filling the space between the label and the buttons
    InputList := TCheckListBox.Create(InputForm);
    InputList.Parent := InputForm;
    InputList.Align := alClient;
    InputList.BorderSpacing.Left := InputForm.Scale96ToForm(12);
    InputList.BorderSpacing.Right := InputForm.Scale96ToForm(12);
    // Bottom margin reserves the vertical space occupied by the buttons plus a small gap
    InputList.BorderSpacing.Bottom := InputForm.Scale96ToForm(12) + InputForm.Scale96ToForm(25) + InputForm.Scale96ToForm(12);
    InputList.TabOrder := 1;

    // Attach the filter helper that keeps check states while filtering
    FilterHelper := TCheckListFilterHelper.Create(FilterEdit, InputList, AItems, AValues, ASelectedValues);

    // Create the OK button, anchored to the bottom-right corner
    BtnOK := TButton.Create(InputForm);
    BtnOK.Parent := InputForm;
    BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOk;
    BtnOK.Default := True;
    BtnOK.Width := InputForm.Scale96ToForm(75);
    BtnOK.Height := InputForm.Scale96ToForm(25);
    BtnOK.Anchors := [akRight, akBottom];
    BtnOK.TabOrder := 2;

    // Create the Cancel button next to OK, also anchored to the bottom-right corner
    BtnCancel := TButton.Create(InputForm);
    BtnCancel.Parent := InputForm;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;
    BtnCancel.Width := InputForm.Scale96ToForm(75);
    BtnCancel.Height := InputForm.Scale96ToForm(25);
    BtnCancel.Anchors := [akRight, akBottom];
    BtnCancel.TabOrder := 3;

    // Set the initial client height so the list starts with the requested height
    InputForm.ClientHeight := InputForm.Scale96ToForm(12) + PromptLabel.Height + InputForm.Scale96ToForm(6) +
      FilterEdit.Height + InputForm.Scale96ToForm(6) + AHeight + InputForm.Scale96ToForm(12) + BtnOK.Height +
      InputForm.Scale96ToForm(12);

    // Position the buttons near the bottom-right corner of the initial layout
    BtnOK.Top := InputForm.ClientHeight - BtnOK.Height - InputForm.Scale96ToForm(12);
    BtnOK.Left := InputForm.ClientWidth - (BtnOK.Width * 2) - InputForm.Scale96ToForm(18);
    BtnCancel.Top := BtnOK.Top;
    BtnCancel.Left := InputForm.ClientWidth - BtnCancel.Width - InputForm.Scale96ToForm(12);

    // Give the filter edit focus so the user can start typing right away
    InputForm.ActiveControl := FilterEdit;

    // Show the dialog and check the result
    if InputForm.ShowModal = mrOk then
    begin
      ASelectedValues := FilterHelper.CollectSelectedValues;
      Result := True;
    end;
  finally
    FilterHelper.Free;
    InputForm.Free;
  end;
end;

class function TDialogUtils.StringListQueryLite(const ACaption: string; AValues: TStrings; AReadOnly: boolean;
  AWidth: integer; AHeight: integer; ANameColumnWidth: integer; GridLineColor: TColor = clNone;
  AlternateColor: TColor = clNone): TStringList;
var
  InputForm: TForm = nil;
  ValueEditor: TValueListEditor = nil;
  BtnOK: TButton = nil;
  BtnCancel: TButton = nil;
begin
  Result := nil;

  if AValues = nil then
    Exit;

  InputForm := TForm.Create(nil);
  try
    // Scale design pixel sizes to the current DPI of the form
    AWidth := InputForm.Scale96ToForm(AWidth);
    AHeight := InputForm.Scale96ToForm(AHeight);
    ANameColumnWidth := InputForm.Scale96ToForm(ANameColumnWidth);

    InputForm.Caption := ACaption;
    InputForm.Position := poScreenCenter;
    InputForm.BorderStyle := bsSizeable;
    InputForm.Width := AWidth;
    InputForm.ClientHeight := AHeight;

    // Keep the dialog usable when resized
    InputForm.Constraints.MinWidth := InputForm.Scale96ToForm(350);
    InputForm.Constraints.MinHeight := InputForm.Scale96ToForm(200);

    // Create the value editor
    ValueEditor := TValueListEditor.Create(InputForm);
    ValueEditor.Parent := InputForm;
    ValueEditor.Align := alClient;
    ValueEditor.BorderSpacing.Around := InputForm.Scale96ToForm(12);

    if GridLineColor <> clNone then
      ValueEditor.GridLineColor := GridLineColor;
    if AlternateColor <> clNone then
      ValueEditor.AlternateColor := AlternateColor;

    // Initialize the editor columns
    ValueEditor.Strings.NameValueSeparator := '=';
    ValueEditor.Strings.Assign(AValues);

    ValueEditor.TitleCaptions.Clear;
    ValueEditor.TitleCaptions.Add('Name');
    ValueEditor.TitleCaptions.Add('Value');

    ValueEditor.ColWidths[0] := ANameColumnWidth;
    ValueEditor.Options := ValueEditor.Options + [goColSizing, goRangeSelect, goDrawFocusSelected, goRowHighlight];

    if AReadOnly then
    begin
      // Disable editing in read-only mode
      ValueEditor.Options := ValueEditor.Options - [goEditing];
      ValueEditor.KeyOptions := [];
    end;

    // Create the OK button
    BtnOK := TButton.Create(InputForm);
    BtnOK.Parent := InputForm;
    if AReadOnly then
      BtnOK.Caption := 'Close'
    else
      BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOk;
    BtnOK.Cancel := AReadOnly;
    BtnOK.Default := True;
    BtnOK.Width := InputForm.Scale96ToForm(75);
    BtnOK.Height := InputForm.Scale96ToForm(25);
    BtnOK.Anchors := [akRight, akBottom];

    // Create the Cancel button only in editing mode
    if not AReadOnly then
    begin
      BtnCancel := TButton.Create(InputForm);
      BtnCancel.Parent := InputForm;
      BtnCancel.Caption := 'Cancel';
      BtnCancel.ModalResult := mrCancel;
      BtnCancel.Cancel := True;
      BtnCancel.Default := True;
      BtnCancel.Width := InputForm.Scale96ToForm(75);
      BtnCancel.Height := InputForm.Scale96ToForm(25);
      BtnCancel.Anchors := [akRight, akBottom];
    end;

    // Position buttons at the bottom-right corner
    BtnOK.Left := InputForm.ClientWidth - BtnOK.Width - InputForm.Scale96ToForm(12);
    BtnOK.Top := InputForm.ClientHeight - BtnOK.Height - InputForm.Scale96ToForm(12);

    if BtnCancel <> nil then
    begin
      BtnCancel.Left := BtnOK.Left - BtnCancel.Width - InputForm.Scale96ToForm(6);
      BtnCancel.Top := BtnOK.Top;
    end;

    // Reserve space for the buttons
    ValueEditor.BorderSpacing.Bottom := InputForm.Scale96ToForm(12) + BtnOK.Height + InputForm.Scale96ToForm(12);

    if InputForm.ShowModal = mrOk then
    begin
      Result := TStringList.Create;
      Result.Assign(ValueEditor.Strings);
    end;
  finally
    InputForm.Free;
  end;
end;

{%EndRegion}

end.
