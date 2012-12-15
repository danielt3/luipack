unit MainView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Grids, fpjson, AddressBookClient;

type

  { TMainForm }

  TMainForm = class(TForm)
    AddContactButton: TButton;
    EditContactButton: TButton;
    DeleteContactButton: TButton;
    AddPhoneButton: TButton;
    EditPhoneButton: TButton;
    DeletePhoneButton: TButton;
    Label1: TLabel;
    PhonesLabel: TLabel;
    LoadDataButton: TButton;
    BaseURLEdit: TLabeledEdit;
    ContactsGrid: TStringGrid;
    PhonesGrid: TStringGrid;
    procedure AddContactButtonClick(Sender: TObject);
    procedure AddPhoneButtonClick(Sender: TObject);
    procedure ContactsGridSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure DeleteContactButtonClick(Sender: TObject);
    procedure DeletePhoneButtonClick(Sender: TObject);
    procedure EditContactButtonClick(Sender: TObject);
    procedure EditPhoneButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadDataButtonClick(Sender: TObject);
  private
    function GetSelectedContact: TJSONObject;
    function GetSelectedPhone: TJSONObject;
    procedure ResponseSuccess(ResourceTag: PtrInt; Method: THTTPMethodType; ResponseCode: Integer; ResponseStream: TStream);
    procedure ResponseError(ResourceTag: PtrInt; Method: THTTPMethodType; ResponseCode: Integer; ResponseStream: TStream);
    procedure SocketError(Sender: TObject; ErrorCode: Integer; const ErrorDescription: String);
    procedure UpdateContactsView;
    procedure UpdateContactPhones(ContactData: TJSONObject);
    procedure UpdatePhonesView;
  private
    { private declarations }
    FContacts: TJSONArray;
    FContactPhones: TJSONArray;
    FRESTClient: TAddressBookRESTClient;
    property SelectedContact: TJSONObject read GetSelectedContact;
    property SelectedPhone: TJSONObject read GetSelectedPhone;
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  LuiJSONUtils, ContactView, PhoneView;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FContactPhones.Free;
  FContacts.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FRESTClient := TAddressBookRESTClient.Create(Self);
  FRESTClient.OnResponseSuccess := @ResponseSuccess;
  FRESTClient.OnResponseError := @ResponseError;
  FRESTClient.OnSocketError := @SocketError;
end;

procedure TMainForm.ContactsGridSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
var
  ContactData: TJSONObject;
begin
  if (aRow > 0) and (aRow <= FContacts.Count) then
  begin
    ContactData := FContacts.Objects[aRow - 1];
    UpdateContactPhones(ContactData);
  end;
end;

procedure TMainForm.DeleteContactButtonClick(Sender: TObject);
var
  ContactData: TJSONObject;
  ResourcePath: String;
begin
  ContactData := SelectedContact;
  if ContactData = nil then
    Exit;
  ResourcePath := Format('contacts/%d', [ContactData.Integers['id']]);
  if FRESTClient.Delete(ResourcePath, RES_CONTACT) then
  begin
    FContacts.Remove(ContactData);
    UpdateContactsView;
  end;
end;

procedure TMainForm.DeletePhoneButtonClick(Sender: TObject);
var
  PhoneData, ContactData: TJSONObject;
  ResourcePath: String;
begin
  ContactData := SelectedContact;
  PhoneData := SelectedPhone;
  if (ContactData = nil) or (PhoneData = nil) then
    Exit;
  ResourcePath := Format('contacts/%d/phones/%d', [ContactData.Integers['id'], PhoneData.Integers['id']]);
  if FRESTClient.Delete(ResourcePath, RES_CONTACTPHONE) then
  begin
    FContactPhones.Remove(PhoneData);
    UpdatePhonesView;
  end;
end;

procedure TMainForm.EditContactButtonClick(Sender: TObject);
var
  ContactData: TJSONObject;
  ResourcePath: String;
begin
  ContactData := SelectedContact;
  if ContactData = nil then
    Exit;
  if TContactViewForm.EditData(Self, ContactData) then
  begin
    ResourcePath := Format('contacts/%d', [ContactData.Integers['id']]);
    FRESTClient.Put(ResourcePath, RES_CONTACT, ContactData.AsJSON);
  end;
end;

procedure TMainForm.EditPhoneButtonClick(Sender: TObject);
var
  PhoneData, ContactData: TJSONObject;
  ResourcePath: String;
begin
  ContactData := SelectedContact;
  PhoneData := SelectedPhone;
  if (ContactData = nil) or (PhoneData = nil) then
    Exit;
  if TPhoneViewForm.EditData(Self, PhoneData) then
  begin
    ResourcePath := Format('contacts/%d/phones/%d', [ContactData.Integers['id'], PhoneData.Integers['id']]);
    FRESTClient.Put(ResourcePath, RES_CONTACTPHONE, PhoneData.AsJSON);
  end;
end;

procedure TMainForm.AddContactButtonClick(Sender: TObject);
var
  ContactData: TJSONObject;
begin
  ContactData := TJSONObject.Create(['name', 'New Contact']);
  if TContactViewForm.EditData(Self, ContactData) then
    FRESTClient.Post('contacts', RES_CONTACTS, ContactData.AsJSON);
  ContactData.Destroy;
end;

procedure TMainForm.AddPhoneButtonClick(Sender: TObject);
var
  PhoneData, ContactData: TJSONObject;
  ResourcePath: String;
begin
  ContactData := SelectedContact;
  if ContactData = nil then
    Exit;
  PhoneData := TJSONObject.Create(['number', 'New Number']);
  if TPhoneViewForm.EditData(Self, PhoneData) then
  begin
    ResourcePath := Format('contacts/%d/phones', [ContactData.Integers['id']]);
    FRESTClient.Post(ResourcePath, RES_CONTACTPHONES, PhoneData.AsJSON);
  end;
  PhoneData.Destroy;
end;

procedure TMainForm.LoadDataButtonClick(Sender: TObject);
begin
  FRESTClient.BaseURL := BaseURLEdit.Text;
  FRESTClient.Get('contacts', RES_CONTACTS);
end;

procedure TMainForm.ResponseSuccess(ResourceTag: PtrInt; Method: THTTPMethodType;
  ResponseCode: Integer; ResponseStream: TStream);
var
  ResponseData: TJSONData;
begin
  ResponseData := StreamToJSONData(ResponseStream);
  case ResourceTag of
    RES_CONTACTS:
      begin
        case Method of
          hmtGet:
          begin
            if (ResponseData <> nil) and (ResponseData.JSONType = jtArray) then
            begin
              FContacts.Free;
              FContacts := TJSONArray(ResponseData);
              UpdateContactsView;
            end;
          end;
          hmtPost:
          begin
            FContacts.Add(ResponseData);
            UpdateContactsView;
          end;
        end;
      end;
    RES_CONTACT:
      begin
        case Method of
          hmtPut:
          begin
            if (ResponseData <> nil) and (ResponseData.JSONType = jtObject) then
            begin
              PhonesLabel.Caption := TJSONObject(ResponseData).Strings['name'] + ' Phones';
              UpdateContactsView;
            end;
          end;
        end;
      end;
    RES_CONTACTPHONES:
      begin
        case Method of
          hmtGet:
          begin
            if (ResponseData <> nil) and (ResponseData.JSONType = jtArray) then
            begin
              FContactPhones.Free;
              FContactPhones := TJSONArray(ResponseData);
              UpdatePhonesView;
            end;
          end;
          hmtPost:
          begin
            FContactPhones.Add(ResponseData);
            UpdatePhonesView;
          end;
        end;
      end;
    RES_CONTACTPHONE:
      begin
        case Method of
          hmtPut:
          begin
            UpdatePhonesView;
          end;
        end;
      end;
  end;
end;

procedure TMainForm.ResponseError(ResourceTag: PtrInt; Method: THTTPMethodType;
  ResponseCode: Integer; ResponseStream: TStream);
var
  ResponseData: TJSONData;
  Message: String;
begin
  Message := '';
  ResponseData := StreamToJSONData(ResponseStream);
  if (ResponseData <> nil) and (ResponseData.JSONType = jtObject) then
  begin
    Message := GetJSONProp(TJSONObject(ResponseData), 'message', '');
    if Message <> '' then
      Message := LineEnding + Message;
  end;
  ShowMessageFmt('Server response error%s', [Message]);
end;

procedure TMainForm.SocketError(Sender: TObject; ErrorCode: Integer;
  const ErrorDescription: String);
begin
  ShowMessageFmt('Socket Error: "%s"', [ErrorDescription]);
end;

function TMainForm.GetSelectedContact: TJSONObject;
begin
  if (ContactsGrid.Selection.Top > 0) and (ContactsGrid.Selection.Top <= FContacts.Count) then
    Result := FContacts.Objects[ContactsGrid.Selection.Top - 1]
  else
    Result := nil;
end;

function TMainForm.GetSelectedPhone: TJSONObject;
begin
  if (PhonesGrid.Selection.Top > 0) and (PhonesGrid.Selection.Top <= FContactPhones.Count) then
    Result := FContactPhones.Objects[PhonesGrid.Selection.Top - 1]
  else
    Result := nil;
end;

procedure TMainForm.UpdateContactsView;
var
  i: Integer;
  ContactData: TJSONObject;
begin
  ContactsGrid.RowCount := FContacts.Count + 1;
  for i := 0 to FContacts.Count -1 do
  begin
    ContactData := FContacts.Objects[i];
    ContactsGrid.Cells[0, i + 1] := ContactData.Strings['id'];
    ContactsGrid.Cells[1, i + 1] := ContactData.Strings['name'];
  end;
end;

procedure TMainForm.UpdateContactPhones(ContactData: TJSONObject);
var
  ResourcePath: String;
begin
  if ContactData = nil then
    Exit;
  PhonesLabel.Caption := ContactData.Strings['name'] + ' Phones';
  ResourcePath := Format('contacts/%d/phones', [ContactData.Integers['id']]);
  FRESTClient.Get(ResourcePath, RES_CONTACTPHONES);
end;

procedure TMainForm.UpdatePhonesView;
var
  i: Integer;
  PhoneData: TJSONObject;
begin
  PhonesGrid.RowCount := FContactPhones.Count + 1;
  for i := 0 to FContactPhones.Count -1 do
  begin
    PhoneData := FContactPhones.Objects[i];
    PhonesGrid.Cells[0, i + 1] := PhoneData.Strings['id'];
    PhonesGrid.Cells[1, i + 1] := PhoneData.Strings['number'];
  end;
end;

end.

