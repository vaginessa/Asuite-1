{
Copyright (C) 2006-2021 Matteo Salvi

Website: http://www.salvadorsoftware.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
}

unit Frame.Options.Autorun;

{$MODE DelphiUnicode}

interface

uses
  LCLIntf, SysUtils, Classes, Controls, Dialogs, Frame.BaseEntity,
  StdCtrls, VirtualTrees, Lists.Base, Menus, ExtCtrls, Buttons, ActnList;

type

  { TfrmAutorunOptionsPage }

  TfrmAutorunOptionsPage = class(TfrmBaseEntityPage)
    actRemoveAutorun: TAction;
    actProperties: TAction;
    ActionList1: TActionList;
    btnShutdownDelete: TSpeedButton;
    btnShutdownDown: TSpeedButton;
    btnShutdownUp: TSpeedButton;
    btnStartupDelete: TSpeedButton;
    btnStartupDown: TSpeedButton;
    btnStartupUp: TSpeedButton;
    chkShutdown: TCheckBox;
    grpShutdownOrderItems: TGroupBox;
    
    grpStartupOrderItems: TGroupBox;
    chkStartup: TCheckBox;
    lblShutdownInfo: TLabel;
    lblStartupInfo: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    pmAutorun: TPopupMenu;
    mniRemoveAutorun: TMenuItem;
    mniN1: TMenuItem;
    mniProperties: TMenuItem;
    vstShutdownItems: TVirtualStringTree;
    vstStartupItems: TVirtualStringTree;
    procedure actPropertiesExecute(Sender: TObject);
    procedure actRemoveAutorunExecute(Sender: TObject);
    procedure actMenuItemUpdate(Sender: TObject);
    procedure btnStartupUpClick(Sender: TObject);
    procedure btnShutdownUpClick(Sender: TObject);
    procedure btnStartupDeleteClick(Sender: TObject);
    procedure btnShutdownDeleteClick(Sender: TObject);
    procedure btnStartupDownClick(Sender: TObject);
    procedure btnShutdownDownClick(Sender: TObject);
    procedure vstGetPopupMenu(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex; const P: TPoint;
      var AskParent: Boolean; var PopupMenu: TPopupMenu);
  private
    { Private declarations }
    FActiveTree: TBaseVirtualTree;
    procedure MoveItemUp(const ATree: TBaseVirtualTree);
    procedure MoveItemDown(const ATree: TBaseVirtualTree);
    procedure RemoveItem(const ATree: TBaseVirtualTree);
    procedure SaveInAutorunItemList(const ATree: TBaseVirtualTree;const AutorunItemList: TBaseItemsList);
    function  GetActiveTree: TBaseVirtualTree;
    procedure LoadGlyphs;
    procedure ChangeButtonGlyph(AButton: TSpeedButton; AImageKey: string);
  strict protected
    function GetTitle: string; override;
    function GetImageIndex: Integer; override;
    function InternalLoadData: Boolean; override;
    function InternalSaveData: Boolean; override;
  public
    { Public declarations }
  end;

var
  frmAutorunOptionsPage: TfrmAutorunOptionsPage;

implementation

uses
  NodeDataTypes.Custom, AppConfig.Main, DataModules.Icons, Graphics, Kernel.Manager,
  VirtualTree.Methods, Kernel.ResourceStrings, Kernel.Enumerations,
  Utility.Misc, Kernel.Instance;

{$R *.lfm}

{ TfrmItemsOptionsPage }

procedure TfrmAutorunOptionsPage.btnShutdownDeleteClick(Sender: TObject);
begin
  RemoveItem(vstShutdownItems);
end;

procedure TfrmAutorunOptionsPage.btnShutdownDownClick(Sender: TObject);
begin
  MoveItemDown(vstShutdownItems);
end;

procedure TfrmAutorunOptionsPage.btnShutdownUpClick(Sender: TObject);
begin
  MoveItemUp(vstShutdownItems);
end;

procedure TfrmAutorunOptionsPage.btnStartupDeleteClick(Sender: TObject);
begin
  RemoveItem(vstStartupItems);
end;

procedure TfrmAutorunOptionsPage.btnStartupDownClick(Sender: TObject);
begin
  MoveItemDown(vstStartupItems);
end;

procedure TfrmAutorunOptionsPage.btnStartupUpClick(Sender: TObject);
begin
  MoveItemUp(vstStartupItems);
end;

procedure TfrmAutorunOptionsPage.actPropertiesExecute(Sender: TObject);
begin
  TVirtualTreeMethods.ShowItemProperty(Self, GetActiveTree, GetActiveTree.FocusedNode);
end;

procedure TfrmAutorunOptionsPage.actRemoveAutorunExecute(Sender: TObject);
begin
  if AskUserWarningMessage(msgConfirm, []) and Assigned(GetActiveTree.FocusedNode) then
    GetActiveTree.IsVisible[GetActiveTree.FocusedNode] := False;
end;

procedure TfrmAutorunOptionsPage.actMenuItemUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := TVirtualTreeMethods.HasSelectedNodes(GetActiveTree);
end;

function TfrmAutorunOptionsPage.GetActiveTree: TBaseVirtualTree;
begin
  Result := FActiveTree;
end;

function TfrmAutorunOptionsPage.GetImageIndex: Integer;
begin
  Result := ASuiteManager.IconsManager.GetIconIndex('autorun');
end;

function TfrmAutorunOptionsPage.GetTitle: string;
begin
  Result := msgAutorun;
end;

function TfrmAutorunOptionsPage.InternalLoadData: Boolean;
begin
  Result := inherited;
  FActiveTree := vstStartupItems;
  ASuiteInstance.VSTEvents.SetupVSTAutorun(vstStartupItems);
  ASuiteInstance.VSTEvents.SetupVSTAutorun(vstShutdownItems);
  //Startup
  ChangeButtonGlyph(btnStartupUp, 'arrow_up');
  ChangeButtonGlyph(btnStartupDelete, 'delete');
  ChangeButtonGlyph(btnStartupDown, 'arrow_down');
  //Shutdown
  ChangeButtonGlyph(btnShutdownUp, 'arrow_up');
  ChangeButtonGlyph(btnShutdownDelete, 'delete');
  ChangeButtonGlyph(btnShutdownDown, 'arrow_down');
  //Autorun
  chkStartup.Checked  := Config.AutorunStartup;
  chkShutdown.Checked := Config.AutorunShutdown;
  //Populate lstStartUp and lstShutdown
  TVirtualTreeMethods.PopulateVSTItemList(vstStartupItems, ASuiteManager.ListManager.StartupItemList);
  TVirtualTreeMethods.PopulateVSTItemList(vstShutdownItems, ASuiteManager.ListManager.ShutdownItemList);

  LoadGlyphs;
end;

function TfrmAutorunOptionsPage.InternalSaveData: Boolean;
begin
  Result := inherited;
  //Autorun
  Config.AutorunStartup  := chkStartup.Checked;
  Config.AutorunShutdown := chkShutdown.Checked;
  //Save Startup and Shutdown lists
  SaveInAutorunItemList(vstStartupItems, ASuiteManager.ListManager.StartupItemList);
  SaveInAutorunItemList(vstShutdownItems, ASuiteManager.ListManager.ShutdownItemList);
end;

procedure TfrmAutorunOptionsPage.ChangeButtonGlyph(AButton: TSpeedButton;
  AImageKey: string);
var
  ABMP: TBitmap;
begin
  ABMP := TBitmap.Create;
  try
    dmImages.GetAlphaBitmapFromImageList(ABMP, ASuiteManager.IconsManager.GetIconIndex(AImageKey));
    AButton.Glyph := ABMP;
  finally
    ABMP.Free;
  end;
end;

procedure TfrmAutorunOptionsPage.LoadGlyphs;
begin
  mniProperties.ImageIndex   := ASuiteManager.IconsManager.GetIconIndex('property');
end;

procedure TfrmAutorunOptionsPage.MoveItemUp(const ATree: TBaseVirtualTree);
begin
  if Assigned(ATree.FocusedNode) then
    if ATree.GetFirst <> ATree.FocusedNode then
      ATree.MoveTo(ATree.FocusedNode, ATree.GetPrevious(ATree.FocusedNode), amInsertBefore, False);
end;

procedure TfrmAutorunOptionsPage.MoveItemDown(const ATree: TBaseVirtualTree);
begin
  if Assigned(ATree.FocusedNode) then
    if ATree.GetLast <> ATree.FocusedNode then
      ATree.MoveTo(ATree.FocusedNode, ATree.GetNext(ATree.FocusedNode), amInsertAfter, False);
end;

procedure TfrmAutorunOptionsPage.RemoveItem(const ATree: TBaseVirtualTree);
begin
  if Assigned(ATree.FocusedNode) and AskUserWarningMessage(msgConfirm, []) then
    ATree.IsVisible[ATree.FocusedNode] := False;
end;

procedure TfrmAutorunOptionsPage.SaveInAutorunItemList(
  const ATree: TBaseVirtualTree; const AutorunItemList: TBaseItemsList);
var
  Node : PVirtualNode;
  NodeData: TvCustomRealNodeData;
begin
  AutorunItemList.Clear;
  Node := ATree.GetFirst;
  while Assigned(Node) do
  begin
    NodeData := TvCustomRealNodeData(TVirtualTreeMethods.GetNodeItemData(Node, ATree));
    if Assigned(NodeData) then
    begin
      if ATree.IsVisible[Node] then
        NodeData.AutorunPos := AutorunItemList.AddItem(NodeData)
      else
        NodeData.Autorun := atNever;
      NodeData.Changed := True;
    end;
    Node := ATree.GetNext(Node);
  end;
end;

procedure TfrmAutorunOptionsPage.vstGetPopupMenu(
  Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  const P: TPoint; var AskParent: Boolean; var PopupMenu: TPopupMenu);
begin
  FActiveTree := Sender;
  PopupMenu := pmAutorun;
end;

end.
