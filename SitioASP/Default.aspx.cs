using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ModelEF;

public partial class _Default : System.Web.UI.Page
{
    List<PaquetesViajes> _ListaPaquetesViajes = null;
    List<Estados> _ListaEstados = null;    
    List<PaquetesViajes> _ListaFiltro = null;

    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            if (Application["MiContexto"] == null)
                Application["MiContexto"] = new BiosTravelEntities();

            if (!IsPostBack)
            {
                BiosTravelEntities MiContexto = Application["MiContexto"] as BiosTravelEntities;                

                _ListaPaquetesViajes = (from unPV in MiContexto.PaquetesViajes
                                        where unPV.VuelosI.fechaHoraP > DateTime.Now
                                        orderby unPV.VuelosI.fechaHoraP
                                        select unPV
                                        ).ToList();

                _ListaEstados = (from unE in MiContexto.Estados
                                 where unE.activoE == true
                                 select unE
                                ).ToList();

                Session["ListaPaquetesViajes"] = _ListaPaquetesViajes;
                Session["ListaEstados"] = _ListaEstados;
                Session["ListaFiltro"] = _ListaFiltro = null;

                if (_ListaPaquetesViajes.Count > 0)
                {
                    Session["ListaPaquetesViajes"] = _ListaPaquetesViajes;
                }
                else
                {
                    Session["ListaPaquetesViajes"] = _ListaPaquetesViajes = null;
                    LblError.Text = "No hay viajes disponibles";
                }
                CargoFormulario();
            }
            else
            {
                _ListaPaquetesViajes = Session["ListaPaquetesViajes"] as List<PaquetesViajes>;
                _ListaEstados = Session["ListaEstados"] as List<Estados>;                
                _ListaFiltro = Session["ListaFiltro"] as List<PaquetesViajes>;           
            }            
        }
        catch (Exception ex)
        {
            LblError.Text = ex.Message;
        }
    }

    private void CargoFormulario()
    {
        try
        {
            // limpio todo
            LblError.Text = "";
            TxtCantDias.Text = "";
            TxtMesAño.Text = "";
            Session["ListaFiltro"] = _ListaFiltro = null;

            // limpio gran formulario
            lblTitulo.Text = "";
            lblEstado.Text = "";
            txtDescripcion.Text = "";
            lblCantDias.Text = "";
            lblP1.Text = "";
            lblP2.Text = "";
            lblP3.Text = "";
            txtVPHoraPartida.Text = "";
            txtVPHoraLlegada.Text = "";
            txtVPPrecio.Text = "";
            txtVPPartida.Text = "";
            txtVPDestino.Text = "";
            txtVLHoraPartida.Text = "";
            txtVLHoraLlegada.Text = "";
            txtVLPrecio.Text = "";
            txtVLPartida.Text = "";
            txtVLDestino.Text = "";
            GvHospedaje.DataSource = null;
            GvHospedaje.DataBind();


            // cargo dropdownlist de Estados
            DdlEstados.DataSource = _ListaEstados;
            DdlEstados.DataTextField = "nombre";
            DdlEstados.DataValueField = "codigo";
            DdlEstados.DataBind();
            DdlEstados.Items.Insert(0, "Seleccione un Estado");
            DdlEstados.SelectedIndex = 0;

            // cargo grilla de los PaquetesViajes
            GvViajes.DataSource = _ListaPaquetesViajes;
            GvViajes.DataBind();
        }
        catch (Exception ex)
        {
            LblError.Text = ex.Message;
        }        
    }

    protected void GvViajes_PageIndexChanging(object sender, GridViewPageEventArgs e)
    {
        try
        {
            GvViajes.PageIndex = e.NewPageIndex;

            List<PaquetesViajes> _listaFuente = (_ListaFiltro == null) ? _ListaPaquetesViajes : _ListaFiltro;

            GvViajes.DataSource = _listaFuente;
            GvViajes.DataBind();
        }
        catch (Exception ex)
        {
            LblError.Text = ex.Message;
        }        
    }

    protected void GvViajes_SelectedIndexChanged(object sender, EventArgs e)
    {
        try
        {
            // limpio gran formulario primero
            lblTitulo.Text = "";
            lblEstado.Text = "";
            txtDescripcion.Text = "";
            lblCantDias.Text = "";
            lblP1.Text = "";
            lblP2.Text = "";
            lblP3.Text = "";
            txtVPHoraPartida.Text = "";
            txtVPHoraLlegada.Text = "";
            txtVPPrecio.Text = "";
            txtVPPartida.Text = "";
            txtVPDestino.Text = "";
            txtVLHoraPartida.Text = "";
            txtVLHoraLlegada.Text = "";
            txtVLPrecio.Text = "";
            txtVLPartida.Text = "";
            txtVLDestino.Text = "";
            GvHospedaje.DataSource = null;
            GvHospedaje.DataBind();


            int pos = (GvViajes.PageIndex * GvViajes.PageSize) + GvViajes.SelectedIndex;

            PaquetesViajes unPV = null;

            if (_ListaFiltro == null)
            {
                unPV = _ListaPaquetesViajes[pos];
            }
            else
            {
                unPV = _ListaFiltro[pos];
            }

            lblTitulo.Text = unPV.titulo;
            lblEstado.Text = unPV.Estados.nombre;
            txtDescripcion.Text = unPV.descripcion;
            lblCantDias.Text = unPV.cantidadDiasP.ToString();
            lblP1.Text = unPV.precioIndividual.ToString();
            lblP2.Text = unPV.precioDosP.ToString();
            lblP3.Text = unPV.precioTresP.ToString();
            txtVPHoraPartida.Text = unPV.VuelosI.fechaHoraP.ToShortDateString();
            txtVPHoraLlegada.Text = unPV.VuelosI.fechaHoraL.ToShortDateString();
            txtVPPrecio.Text = unPV.VuelosI.precioV.ToString();
            txtVPPartida.Text = unPV.VuelosI.EstadosP.nombre;
            txtVPDestino.Text = unPV.VuelosI.EstadosA.nombre;
            txtVLHoraPartida.Text = unPV.VuelosV.fechaHoraP.ToShortDateString();
            txtVLHoraLlegada.Text = unPV.VuelosI.fechaHoraL.ToShortDateString();
            txtVLPrecio.Text = unPV.VuelosV.precioV.ToString();
            txtVLPartida.Text = unPV.VuelosV.EstadosP.nombre;
            txtVLDestino.Text = unPV.VuelosV.EstadosA.nombre;
            GvHospedaje.DataSource = unPV.Incluyen.ToList();
            GvHospedaje.DataBind();

        }
        catch (Exception ex)
        {
            LblError.Text = ex.Message;
        }
    }

    protected void BtnLimpiar_Click(object sender, EventArgs e)
    {
        try
        {
            CargoFormulario();
        }
        catch (Exception ex)
        {
            LblError.Text = ex.Message;
        }
    }

    protected void BtnFiltrar_Click(object sender, EventArgs e)
    {
        // limpio gran formulario primero
            lblTitulo.Text = "";
            lblEstado.Text = "";
            txtDescripcion.Text = "";
            lblCantDias.Text = "";
            lblP1.Text = "";
            lblP2.Text = "";
            lblP3.Text = "";
            txtVPHoraPartida.Text = "";
            txtVPHoraLlegada.Text = "";
            txtVPPrecio.Text = "";
            txtVPPartida.Text = "";
            txtVPDestino.Text = "";
            txtVLHoraPartida.Text = "";
            txtVLHoraLlegada.Text = "";
            txtVLPrecio.Text = "";
            txtVLPartida.Text = "";
            txtVLDestino.Text = "";
            GvHospedaje.DataSource = null;
            GvHospedaje.DataBind();

        LblError.Text = "";
        _ListaFiltro = _ListaPaquetesViajes;

        try
        {
            if (DdlEstados.SelectedIndex > 0)
            {
                string codigo = DdlEstados.SelectedValue;
                _ListaFiltro = (from unPV in _ListaFiltro
                                where unPV.Estados.codigo == codigo
                                select unPV
                                ).ToList();
            }
            if (TxtCantDias.Text.Length > 0)
            {
                int cantDias = Convert.ToInt32(TxtCantDias.Text);
                if (cantDias <= 0 || cantDias > 60)
                    throw new Exception("Cantidad días: Ingrese un valor válido, mayor a 0 o menor a 60");

                _ListaFiltro = (from unPV in _ListaFiltro
                                where unPV.cantidadDiasP <= cantDias
                                select unPV
                                ).ToList();
            }
            if (TxtMesAño.Text.Length > 0)
            {
                DateTime fecha = Convert.ToDateTime(TxtMesAño.Text);
                _ListaFiltro = (from unPV in _ListaFiltro
                                where unPV.VuelosI.fechaHoraP.Month == fecha.Month && unPV.VuelosI.fechaHoraP.Year == fecha.Year
                                select unPV
                                ).ToList();
            }
            if (_ListaFiltro.Count == 0)
            {
                GvViajes.DataSource = null;
                GvViajes.DataBind();
                LblError.Text = "No hay viajes con esas especificaciones, intente nuevamente";
            }
            else
            {
                GvViajes.DataSource = _ListaFiltro;
                GvViajes.DataBind();
                Session["ListaFiltro"] = _ListaFiltro;
            }
        }
        catch (Exception ex)
        {
            LblError.Text = ex.Message;
        }
    }
}