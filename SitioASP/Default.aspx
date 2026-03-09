<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>BiosTravel</title>
    <link href="Green.css" rel="stylesheet" type="text/css"/>
</head>
<body>
    <form id="form1" runat="server">
        <header>
            <h1>BiosTravel - Soñá un lugar, nosotros te llevamos hacia él</h1>
            <hr />            
        </header>        
        <main>            
            <div align="center">
                <h2>Elegí tu próximo Viaje</h2>

                <hr />

                <table style="width: 30%;">
                    <tr>
                        <td>
                            <h4>Estado</h4>
                        </td>
                        <td>
                            <asp:DropDownList ID="DdlEstados" runat="server" cssClass="ddlEstados">
                            </asp:DropDownList>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Cantidad de días</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="TxtCantDias" runat="server" TextMode="Number"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Fecha</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="TxtMesAño" runat="server" TextMode="Month"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Button ID="BtnFiltrar" runat="server" Text="Filtrar" OnClick="BtnFiltrar_Click" />
                        </td>
                        <td>
                            <asp:Button ID="BtnLimpiar" runat="server" Text="Limpiar" OnClick="BtnLimpiar_Click" />
                        </td>
                    </tr>
                    <tr>
                        <td></td>
                        <td></td>
                    </tr>
                </table>
                <hr />
                <table style="width: 100%;">                    
                    <asp:Label ID="LblError" runat="server"></asp:Label>
                    <tr>
                        <td style="vertical-align: top">
                            <asp:GridView ID="GvViajes" runat="server" AutoGenerateColumns="False" Height="205px" AllowPaging="True" OnPageIndexChanging="GvViajes_PageIndexChanging" PageSize="30" OnSelectedIndexChanged="GvViajes_SelectedIndexChanged">
                                <Columns>
                                    <asp:BoundField HeaderText="Título" DataField="titulo" />
                                    <asp:BoundField HeaderText="Fecha salida" DataField="VuelosI.fechaHoraP" />
                                    <asp:BoundField HeaderText="Estado" DataField="Estados.nombre" />
                                    <asp:BoundField HeaderText="Precio1" DataField="precioIndividual" />
                                    <asp:BoundField HeaderText="Precio2" DataField="precioDosP" />
                                    <asp:BoundField HeaderText="Precio3" DataField="precioTresP" />
                                    <asp:BoundField HeaderText="Cantidad Días" DataField="cantidadDiasP" />
                                    <asp:CommandField ButtonType="Button" HeaderText="Seleccionar" ShowSelectButton="True" />
                                </Columns>
                            </asp:GridView>
                        </td>                        
                        <td style="vertical-align: top">
                            <table style="width: 30%;">
                    <tr>
                        <td>
                            <h4>Viaje seleccionado</h4></td>
                        <td>
                            <asp:Label ID="lblTitulo" runat="server"></asp:Label>
                        </td>
                    </tr>
                    <tr>
                        <td>                            
                            <h4>Estado</h4>
                        </td>
                        <td>
                            <asp:Label ID="lblEstado" runat="server"></asp:Label>
                            </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Descripción</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtDescripcion" runat="server" Height="42px" ReadOnly="True" TextMode="MultiLine" Width="747px" Rows="5"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Cantidad de días</h4>
                        </td>
                        <td>
                            <asp:Label ID="lblCantDias" runat="server"></asp:Label>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Precio individual</h4>
                        </td>
                        <td>
                            <asp:Label ID="lblP1" runat="server"></asp:Label>
                            </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Precio dos personas</h4>
                        </td>
                        <td>
                            <asp:Label ID="lblP2" runat="server"></asp:Label></td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Precio tres personas</h4>
                        </td>
                        <td>
                            <asp:Label ID="lblP3" runat="server"></asp:Label>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Ida - Horario de partida</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVPHoraPartida" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Ida - Horario de llegada</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVPHoraLlegada" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                     <tr>
                        <td>
                            <h4>Vuelo Ida - Precio</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVPPrecio" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Ida - Lugar de Partida</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVPPartida" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Ida - Lugar de Destino</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVPDestino" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Vuelta - Horario de partida</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVLHoraPartida" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Vuelta - Horario de llegada</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVLHoraLlegada" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                     <tr>
                        <td>
                            <h4>Vuelo Vuelta - Precio</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVLPrecio" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Vuelta - Lugar de Partida</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVLPartida" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <h4>Vuelo Vuelta - Lugar de Destino</h4>
                        </td>
                        <td>
                            <asp:TextBox ID="txtVLDestino" runat="server" ReadOnly="True"></asp:TextBox>
                        </td>
                    </tr>                    
                    <tr>
                        <td>
                            <h4>Alojamientos</h4>
                        </td>
                        <td>
                            <asp:GridView ID="GvHospedaje" runat="server" AutoGenerateColumns="False">
                                <Columns>
                                    <asp:BoundField DataField="Hospedajes.nombre" HeaderText="Nombre" />
                                    <asp:BoundField DataField="Hospedajes.tipoH" HeaderText="Tipo" />
                                    <asp:BoundField DataField="Hospedajes.precioH" HeaderText="Precio" />
                                    <asp:BoundField DataField="Hospedajes.Estados.nombre" HeaderText="Ubicación" />
                                    <asp:BoundField DataField="cantNoches" HeaderText="Cantidad de noches" />
                                </Columns>
                            </asp:GridView>
                        </td>
                    </tr>
                </table>
                        </td>                        
                    </tr>
                </table>
                <br />
                
            </div>
        </main>
        <hr />
        <footer>
        </footer>
    </form>
</body>
</html>
