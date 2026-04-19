import os
from fpdf import FPDF

class TransportBillTester(FPDF):
    def __init__(self, template_path):
        super().__init__(format='A4', unit='pt')
        self.template_path = template_path

    def add_standard_layout(self, billed_to, date):
        self.add_page()
        # Background
        if os.path.exists(self.template_path):
            self.image(self.template_path, x=0, y=0, w=self.w, h=self.h)
        
        # To Section (Moved 1cm higher ~28.3pt from previous 260pt)
        self.set_y(231.7)
        self.set_left_margin(40)
        self.set_right_margin(40)
        
        # Billed To
        self.set_font("helvetica", "B", 10)
        self.cell(0, 15, "To:", ln=True)
        self.set_font("helvetica", "", 12)
        self.cell(0, 15, billed_to, ln=True)
        
        # Date (Right aligned, kept relative to To section)
        self.set_y(246.7)
        self.set_font("helvetica", "", 12)
        self.cell(0, 15, f"Date: {date}", align='R', ln=True)
        
        self.ln(20)
        
        # Title (Reduced size)
        self.set_text_color(255, 0, 0) # Red
        self.set_font("helvetica", "B", 12)
        self.cell(0, 20, "Only Transporting Bill Charges", align='C', ln=True)
        self.set_text_color(0, 0, 0) # Reset to Black
        self.ln(10)

    def draw_table(self, items, is_static=False):
        # Column widths matching Dart exactly
        cols = [55, 70, 65, 55, 35, 110, 50, 60]
        headers = ["Date", "Lorry No.", "Material", "Challan", "Trips", "Site", "Rate", "Amount"]
        
        # Header
        self.set_font("helvetica", "B", 10)
        for i, header in enumerate(headers):
            self.cell(cols[i], 25, header, border=1, align='C')
        self.ln()
        
        # Items
        self.set_font("helvetica", "", 10)
        total_trips = 0
        total_amount = 0
        
        row_count = 10 if is_static else len(items)
        
        for i in range(row_count):
            if i < len(items):
                item = items[i]
                total_trips += item['trips']
                total_amount += item['trips'] * item['rate']
                
                self.cell(cols[0], 25, item['date'], border=1)
                self.cell(cols[1], 25, item['lorry'], border=1)
                self.cell(cols[2], 25, item['material'], border=1)
                self.cell(cols[3], 25, item['challan'], border=1)
                self.cell(cols[4], 25, str(item['trips']), border=1, align='C')
                self.cell(cols[5], 25, item['site'], border=1)
                self.cell(cols[6], 25, str(item['rate']), border=1, align='R')
                self.cell(cols[7], 25, str(item['trips'] * item['rate']), border=1, align='R')
                self.ln()
            else:
                # Empty rows for Template 3
                for width in cols:
                    self.cell(width, 25, "", border=1)
                self.ln()
                
        # Footer / Totals
        self.set_font("helvetica", "B", 10)
        self.cell(sum(cols[:4]), 25, "", border=0) # Space
        self.cell(cols[4], 25, f"{total_trips} trips", border=1, align='C')
        self.cell(cols[5], 25, "", border=0) # Space
        self.set_text_color(255, 0, 0)
        self.cell(cols[6], 25, "TOTAL", border=1, align='R')
        self.set_text_color(0, 0, 0)
        self.cell(cols[7], 25, str(total_amount), border=1, align='R')
        self.ln(35)
        
        # Rupees in Words
        self.rect(self.get_x(), self.get_y(), self.w - 80, 40)
        self.set_x(self.get_x() + 10)
        self.set_y(self.get_y() + 10)
        self.set_font("helvetica", "B", 12)
        self.cell(150, 15, "RUPEES IN WORDS: ", border=0)
        self.set_text_color(255, 0, 0)
        self.cell(0, 15, "SAMPLE RUPEES IN WORDS ONLY", border=0)
        self.set_text_color(0, 0, 0)
        
    def add_signature(self):
        # Move Y offset 25.5 points (0.9cm) higher
        self.set_y(self.h - 145.5)
        self.set_x(self.w - 200)
        self.ln(40)
        self.set_x(self.w - 200)
        self.set_font("helvetica", "B", 12)
        self.cell(160, 15, "Proprietor Sign", align='C', ln=True)


# Sample Execution
if __name__ == "__main__":
    sample_data = [
        {"date": "19/04/2026", "lorry": "MH 02 GS 1234", "material": "DEBRIS", "challan": "456", "trips": 2, "site": "BKC SITE", "rate": 5000},
        {"date": "20/04/2026", "lorry": "MH 02 FG 5678", "material": "DEBRIS", "challan": "457", "trips": 1, "site": "TIMES TOWER", "rate": 5000},
    ]
    
    # Generate Template 2 (Dynamic)
    pdf2 = TransportBillTester("transport-bill-template.png")
    pdf2.add_standard_layout("ABC Constructions Pvt Ltd", "19/04/2026")
    pdf2.draw_table(sample_data, is_static=False)
    pdf2.add_signature()
    pdf2.output("test_template_2_dynamic.pdf")
    print("Generated: test_template_2_dynamic.pdf")
    
    # Generate Template 3 (Static)
    pdf3 = TransportBillTester("transport-bill-template.png")
    pdf3.add_standard_layout("ABC Constructions Pvt Ltd", "19/04/2026")
    pdf3.draw_table(sample_data, is_static=True)
    pdf3.add_signature()
    pdf3.output("test_template_3_static.pdf")
    print("Generated: test_template_3_static.pdf")
